/**
 * A global manager for loading in GAP asset packages. Assets are referenced by their absolute path names.
 * @author Sam MacPherson
 */

package as3gl.util;

import as3gl.core.Runnable;
import as3gl.display.FlashDisplayObject;
import as3gl.util.concurrent.Job;
import math.BigInteger;
import de.polygonal.ds.DA;
import de.polygonal.ds.HashMap;
import de.polygonal.ds.SLL;
import flash.display.Bitmap;
import flash.display.Loader;
import flash.errors.Error;
import flash.events.Event;
import flash.events.ProgressEvent;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequest;
import flash.utils.ByteArray;
import format.mp3.Data;
import format.swf.Data;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import flash.display.Bitmap;

class Assets implements Job {
	
	private static var _GAP_VERSION_MAJOR:Int = 2;
	private static var _GAP_VERSION_MINOR:Int = 0;
	private static var _ANY:Int = 0;
	private static var _IMAGE:Int = 1;
	private static var _ANIMATION:Int = 2;
	private static var _SOUND:Int = 3;
	private static var _FONT:Int = 4;
	
	private static var _NEXT_GAP_ID:Int = 0;
	
	private static var _instance:Assets = new Assets();
	private static var _root:Asset = new Asset("");
	private static var _loadCount:Int = 0;
	private static var _callbackFunc:Dynamic = null;
	private static var _lookup:HashMap<String, Asset> = new HashMap<String, Asset>();
	private static var _doABC:ByteArray;
	private static var _assetQueue:SLL<AssetLoader> = new SLL<AssetLoader>();
	private static var _peakAssets:Int = -1;
	private static var _downloadStatus:HashMap<URLLoader, Float> = new HashMap<URLLoader, Float>();
	public static var _libraryAssets:Array<DA<Dynamic>> = new Array<DA<Dynamic>>();
	
	private function new () {
	}
	
	public static function load (url:URLRequest, ?sigVerifier:BigInteger = null):Job {
		_loadCount++;
		var loader:GAPLoader = new GAPLoader(url, sigVerifier);
		loader.dataFormat = URLLoaderDataFormat.BINARY;
		loader.addEventListener(Event.COMPLETE, _onComplete);
		loader.addEventListener(ProgressEvent.PROGRESS, _onProgress);
		return _instance;
	}
	
	public static function instance ():Assets {
		return _instance;
	}
	
	private static function _onProgress (event:ProgressEvent):Void {
		_downloadStatus.set(event.target, event.bytesLoaded / event.bytesTotal);
	}
	
	private static function _onComplete (event:Event):Void {
		_loadCount--;
		event.target.removeEventListener(Event.COMPLETE, _onComplete);
		event.target.removeEventListener(ProgressEvent.PROGRESS, _onProgress);
		_downloadStatus.clr(event.target);
		_load(event.target.data, event.target.sigVerifier);
		_checkReady();
	}
	
	private inline static function _load (data:ByteArray, sigVerifier:BigInteger):Void {
		var header:GAPHeader = _readHeader(data);
		if (header.majorVersion == _GAP_VERSION_MAJOR && header.minorVersion == _GAP_VERSION_MINOR) {
			var gapId:Int = _NEXT_GAP_ID++;
			if (header.compressed) {
				data.uncompress();
			}
			try {
				_readLibrary(gapId, header.binOffset, data);
				_readDir(_root, gapId, data);
			} catch (e:Error) {
				throw new Error("Corrupt or invalid asset package.");
			}
		} else {
			throw new Error("Asset package is not up to date. Newest version = " + _GAP_VERSION_MAJOR + "." + _GAP_VERSION_MINOR);
		}
	}
	
	private inline static function _getHeaderSize ():Int {
		return 20;
	}
	
	private inline static function _readHeader (data:ByteArray):GAPHeader {
		if (data.readUTFBytes(3) == "GAP") {
			var header:GAPHeader = new GAPHeader();
			header.majorVersion = data.readShort();
			header.minorVersion = data.readShort();
			var flags:Int = data.readByte();
			header.compressed = (flags & 1) > 0;
			header.signed = (flags & 2) > 0;
			header.libOffset = data.readInt();
			header.dirOffset = data.readInt();
			header.binOffset = data.readInt();
			return header;
		} else {
			throw new Error("Corrupt or invalid asset package.");
		}
	}
	
	private inline static function _readLibrary (gapId:Int, binOffset:Int, data:ByteArray):Void {
		var count:Int = data.readInt();
		_libraryAssets[gapId] = new DA<Dynamic>(count);
		for (i in 0 ... count) {
			_libraryAssets[gapId].pushBack(0);
			data.readUTF();
			var loader:AssetLoader = new AssetLoader(gapId, i, data.readInt(), _copyBinaryData(data, data.readInt() + binOffset + _getHeaderSize()));
			_loadCount++;
			_assetQueue.append(loader);
		}
	}
	
	private static function _readDir (asset:Asset, gapId:Int, data:ByteArray):Void {
		var path:String;
		if (asset.getParent() != null && asset.getParent().getPath() != "") {
			path = asset.getParent().getPath() + "." + data.readUTF();
		} else {
			path = data.readUTF();
		}
		_lookup.set(path, asset);
		asset._setPath(path);
		asset._libId = data.readInt();
		asset._gapId = gapId;
		var len:Int = data.readInt();
		for (i in 0 ... len) {
			asset.setProperty(data.readUTF(), data.readUTF());
		}
		len = data.readInt();
		for (i in 0 ... len) {
			var child:Asset = new Asset("", asset);
			_readDir(child, gapId, data);
			asset.addAsset(child.getName(), child);
		}
	}
	
	private inline static function _generateSWFMP3 (data:ByteArray):ByteArray {
		if (_doABC == null) {
			_buildABC();
		}
		_doABC.position = 0;
		var mp3FileBytes:BytesInput = new BytesInput(Bytes.ofData(data));
		var mp3Reader:format.mp3.Reader = new format.mp3.Reader(mp3FileBytes);
		var mp3:MP3 = mp3Reader.read();
		var mp3Frames:Array<MP3Frame> = mp3.frames;
		var mp3Header:MP3Header = mp3Frames[0].header;
		var dataBytesOutput = new BytesOutput();
		var mp3Writer = new format.mp3.Writer(dataBytesOutput);
		mp3Writer.write(mp3, false);
		var samplingRate:SoundRate;
		switch(mp3Header.samplingRate) {
			case SR_11025: samplingRate = SR11k;
			case SR_22050: samplingRate = SR22k;
			case SR_44100: samplingRate = SR44k;
			default: samplingRate = null;
		}
		var swfBytes:BytesOutput = new BytesOutput();
		var swf:format.swf.Writer = new format.swf.Writer(swfBytes);
		var header:SWFHeader = {version:9, compressed:false, width:550, height:400, fps:12.0, nframes:1};
		var isStereo:Bool;
		switch(mp3Header.channelMode) {
			case Stereo: isStereo = true;
			case JointStereo: isStereo = true;
			case DualChannel: isStereo = true;
			case Mono: isStereo = false;
			default: isStereo = false;
		}
		var sound:SWFTag = TSound(
		{
			sid:1,
			format:SFMP3,
			rate:samplingRate,
			is16bit:true,
			isStereo:isStereo,
			samples:haxe.Int32.ofInt(mp3.sampleCount),
			data:SDMp3(0, dataBytesOutput.getBytes())
		});
		swf.writeHeader(header);
		swf.writeTag(TSandBox(8));
		swf.writeTag(TActionScript3(Bytes.ofData(_doABC)));
		swf.writeTag(sound);
		swf.writeTag(TSymbolClass([{cid:1, className:"__SOUND__"}]));
		swf.writeTag(TShowFrame);
		swf.writeEnd();
		return swfBytes.getBytes().getData();
	}
	
	private static function _buildABC ():Void {
		_doABC = new ByteArray();
		_doABC.writeByte(0x10);
		_doABC.writeByte(0x00);
		_doABC.writeByte(0x2E);
		_doABC.writeByte(0x00);
		_doABC.writeByte(0x00);
		_doABC.writeByte(0x00);
		_doABC.writeByte(0x00);
		_doABC.writeByte(0x08);
		_doABC.writeByte(0x00);
		_doABC.writeByte(0x09);
		_doABC.writeByte(0x5F);
		_doABC.writeByte(0x5F);
		_doABC.writeByte(0x53);
		_doABC.writeByte(0x4F);
		_doABC.writeByte(0x55);
		_doABC.writeByte(0x4E);
		_doABC.writeByte(0x44);
		_doABC.writeByte(0x5F);
		_doABC.writeByte(0x5F);
		_doABC.writeByte(0x0B);
		_doABC.writeByte(0x66);
		_doABC.writeByte(0x6C);
		_doABC.writeByte(0x61);
		_doABC.writeByte(0x73);
		_doABC.writeByte(0x68);
		_doABC.writeByte(0x2E);
		_doABC.writeByte(0x6D);
		_doABC.writeByte(0x65);
		_doABC.writeByte(0x64);
		_doABC.writeByte(0x69);
		_doABC.writeByte(0x61);
		_doABC.writeByte(0x05);
		_doABC.writeByte(0x53);
		_doABC.writeByte(0x6F);
		_doABC.writeByte(0x75);
		_doABC.writeByte(0x6E);
		_doABC.writeByte(0x64);
		_doABC.writeByte(0x06);
		_doABC.writeByte(0x4F);
		_doABC.writeByte(0x62);
		_doABC.writeByte(0x6A);
		_doABC.writeByte(0x65);
		_doABC.writeByte(0x63);
		_doABC.writeByte(0x74);
		_doABC.writeByte(0x0C);
		_doABC.writeByte(0x66);
		_doABC.writeByte(0x6C);
		_doABC.writeByte(0x61);
		_doABC.writeByte(0x73);
		_doABC.writeByte(0x68);
		_doABC.writeByte(0x2E);
		_doABC.writeByte(0x65);
		_doABC.writeByte(0x76);
		_doABC.writeByte(0x65);
		_doABC.writeByte(0x6E);
		_doABC.writeByte(0x74);
		_doABC.writeByte(0x73);
		_doABC.writeByte(0x0F);
		_doABC.writeByte(0x45);
		_doABC.writeByte(0x76);
		_doABC.writeByte(0x65);
		_doABC.writeByte(0x6E);
		_doABC.writeByte(0x74);
		_doABC.writeByte(0x44);
		_doABC.writeByte(0x69);
		_doABC.writeByte(0x73);
		_doABC.writeByte(0x70);
		_doABC.writeByte(0x61);
		_doABC.writeByte(0x74);
		_doABC.writeByte(0x63);
		_doABC.writeByte(0x68);
		_doABC.writeByte(0x65);
		_doABC.writeByte(0x72);
		_doABC.writeByte(0x05);
		_doABC.writeByte(0x16);
		_doABC.writeByte(0x01);
		_doABC.writeByte(0x16);
		_doABC.writeByte(0x03);
		_doABC.writeByte(0x18);
		_doABC.writeByte(0x02);
		_doABC.writeByte(0x16);
		_doABC.writeByte(0x06);
		_doABC.writeByte(0x00);
		_doABC.writeByte(0x05);
		_doABC.writeByte(0x07);
		_doABC.writeByte(0x01);
		_doABC.writeByte(0x02);
		_doABC.writeByte(0x07);
		_doABC.writeByte(0x02);
		_doABC.writeByte(0x04);
		_doABC.writeByte(0x07);
		_doABC.writeByte(0x01);
		_doABC.writeByte(0x05);
		_doABC.writeByte(0x07);
		_doABC.writeByte(0x04);
		_doABC.writeByte(0x07);
		_doABC.writeByte(0x03);
		_doABC.writeByte(0x00);
		_doABC.writeByte(0x00);
		_doABC.writeByte(0x00);
		_doABC.writeByte(0x00);
		_doABC.writeByte(0x00);
		_doABC.writeByte(0x00);
		_doABC.writeByte(0x00);
		_doABC.writeByte(0x00);
		_doABC.writeByte(0x00);
		_doABC.writeByte(0x00);
		_doABC.writeByte(0x00);
		_doABC.writeByte(0x00);
		_doABC.writeByte(0x00);
		_doABC.writeByte(0x01);
		_doABC.writeByte(0x01);
		_doABC.writeByte(0x02);
		_doABC.writeByte(0x08);
		_doABC.writeByte(0x03);
		_doABC.writeByte(0x00);
		_doABC.writeByte(0x01);
		_doABC.writeByte(0x00);
		_doABC.writeByte(0x00);
		_doABC.writeByte(0x00);
		_doABC.writeByte(0x01);
		_doABC.writeByte(0x02);
		_doABC.writeByte(0x01);
		_doABC.writeByte(0x01);
		_doABC.writeByte(0x04);
		_doABC.writeByte(0x01);
		_doABC.writeByte(0x00);
		_doABC.writeByte(0x03);
		_doABC.writeByte(0x00);
		_doABC.writeByte(0x01);
		_doABC.writeByte(0x01);
		_doABC.writeByte(0x05);
		_doABC.writeByte(0x06);
		_doABC.writeByte(0x03);
		_doABC.writeByte(0xD0);
		_doABC.writeByte(0x30);
		_doABC.writeByte(0x47);
		_doABC.writeByte(0x00);
		_doABC.writeByte(0x00);
		_doABC.writeByte(0x01);
		_doABC.writeByte(0x01);
		_doABC.writeByte(0x01);
		_doABC.writeByte(0x06);
		_doABC.writeByte(0x07);
		_doABC.writeByte(0x06);
		_doABC.writeByte(0xD0);
		_doABC.writeByte(0x30);
		_doABC.writeByte(0xD0);
		_doABC.writeByte(0x49);
		_doABC.writeByte(0x00);
		_doABC.writeByte(0x47);
		_doABC.writeByte(0x00);
		_doABC.writeByte(0x00);
		_doABC.writeByte(0x02);
		_doABC.writeByte(0x02);
		_doABC.writeByte(0x01);
		_doABC.writeByte(0x01);
		_doABC.writeByte(0x05);
		_doABC.writeByte(0x17);
		_doABC.writeByte(0xD0);
		_doABC.writeByte(0x30);
		_doABC.writeByte(0x65);
		_doABC.writeByte(0x00);
		_doABC.writeByte(0x60);
		_doABC.writeByte(0x03);
		_doABC.writeByte(0x30);
		_doABC.writeByte(0x60);
		_doABC.writeByte(0x04);
		_doABC.writeByte(0x30);
		_doABC.writeByte(0x60);
		_doABC.writeByte(0x02);
		_doABC.writeByte(0x30);
		_doABC.writeByte(0x60);
		_doABC.writeByte(0x02);
		_doABC.writeByte(0x58);
		_doABC.writeByte(0x00);
		_doABC.writeByte(0x1D);
		_doABC.writeByte(0x1D);
		_doABC.writeByte(0x1D);
		_doABC.writeByte(0x68);
		_doABC.writeByte(0x01);
		_doABC.writeByte(0x47);
		_doABC.writeByte(0x00);
		_doABC.writeByte(0x00);
	}
	
	private static function _onAssetLoad (event:Event):Void {
		_loadCount--;
		event.target.removeEventListener(Event.COMPLETE, _onAssetLoad);
		if (Std.is(event.target.content, Bitmap)) {
			_libraryAssets[event.target.loader.gapId].set(event.target.loader.libId, new FlashDisplayObject(event.target.content.bitmapData));
		} else {
			_libraryAssets[event.target.loader.gapId].set(event.target.loader.libId, new FlashDisplayObject(Type.createInstance(event.target.applicationDomain.getDefinition("mc"), [])));
		}
		event.target.loader.unload();
		_checkReady();
	}
	
	private static function _onSoundLoad (event:Event):Void {
		_loadCount--;
		event.target.removeEventListener(Event.COMPLETE, _onSoundLoad);
		_libraryAssets[event.target.loader.gapId].set(event.target.loader.libId, Type.createInstance(event.target.applicationDomain.getDefinition("__SOUND__"), []));
		event.target.loader.unload();
		_checkReady();
	}
	
	private static function _checkReady ():Void {
		if (_loadCount == 0 && _callbackFunc != null) {
			_callbackFunc();
			_peakAssets = -1;
		}
	}
	
	public static function setCompletionCallback (callbackFunc:Dynamic):Void {
		_callbackFunc = callbackFunc;
	}
	
	/*public static function unload (path:String):Asset {
		var asset:Asset = get(path);
		if (asset != null) {
			if (asset == _root) {
				_root = new Asset("");
				_lookup.clear();
			} else {
				if (Std.is(asset.get(), flash.display.MovieClip)) {
					asset.get().loaderInfo.loader.unload();
				} else if (Std.is(asset.get(), flash.display.BitmapData)) {
					asset.get().dispose();
				}
				asset.getParent().removeAsset(asset);
				_lookup.clr(path);
				for (i in asset.getAssets()) {
					unload(i.getPath());
				}
			}
		}
		return asset;
	}*/
	
	public static function get (path:String):Asset {
		if (path == "") {
			return _root;
		} else {
			return _lookup.get(path);
		}
	}
	
	public function init (vars:Dynamic<Dynamic>):Void {
	}
	
	public function progress ():Float {
		if (_peakAssets == -1) {
			if (this.isComplete()) {
				return 1;
			} else {
				var total:Float = 0;
				for (i in _downloadStatus) {
					total += i / _downloadStatus.size();
				}
				return 0.5 * total;
			}
		} else {
			return 1 - ((0.5 * _loadCount) / _peakAssets);
		}
	}
	
	public function isComplete ():Bool {
		return _loadCount == 0 && _assetQueue.isEmpty();
	}
	
	public function execute (vars:Dynamic<Dynamic>):Bool {
		return _run(vars);
	}
	
	public inline static function _run (vars:Dynamic<Dynamic>):Bool {
		if (_loadCount > 0 && _assetQueue.isEmpty()) {
			return false;
		} else {
			if (_peakAssets == -1) {
				_peakAssets = _loadCount;
			}
			if (!_assetQueue.isEmpty()) {
				var loader:AssetLoader = _assetQueue.removeHead();
				if (loader.type == _ANY) {
					_loadCount--;
					if (loader.data.bytesAvailable > 0) _libraryAssets[loader.gapId].set(loader.libId, loader.data);
					_checkReady();
				} else if (loader.type == _IMAGE || loader.type == _ANIMATION) {
					loader.contentLoaderInfo.addEventListener(Event.COMPLETE, _onAssetLoad);
					loader.loadBytes(loader.data);
				} else if (loader.type == _SOUND) {
					loader.contentLoaderInfo.addEventListener(Event.COMPLETE, _onSoundLoad);
					var swfBytes:ByteArray = _generateSWFMP3(loader.data);
					swfBytes.position = 0;
					loader.loadBytes(swfBytes);
				}
				//TODO add support for fonts
			}
			return _assetQueue.isEmpty();
		}
	}
	
	private static function _copyBinaryData (buf:ByteArray, pos:Int):ByteArray {
		var lastPos:Int = buf.position;
		var bufCpy:ByteArray = new ByteArray();
		buf.position = pos;
		var length:Int = buf.readInt();
		if (length > 0) {
			buf.readBytes(bufCpy, 0, length);
			bufCpy.position = 0;
		}
		buf.position = lastPos;
		return bufCpy;
	}
	
}

private class AssetLoader extends Loader {
	
	public var gapId:Int;
	public var libId:Int;
	public var type:Int;
	public var data:ByteArray;
	
	public function new (gapId:Int, libId:Int, type:Int, data:ByteArray):Void {
		super();
		
		this.gapId = gapId;
		this.libId = libId;
		this.type = type;
		this.data = data;
	}
	
}

private class GAPLoader extends URLLoader {
	
	public var sigVerifier:BigInteger;
	
	public function new (url:URLRequest, sigVerifier:BigInteger):Void {
		super(url);
		
		this.sigVerifier = sigVerifier;
	}
	
}

private class GAPHeader {
	
	public var majorVersion:Int;
	public var minorVersion:Int;
	public var compressed:Bool;
	public var signed:Bool;
	public var libOffset:Int;
	public var dirOffset:Int;
	public var binOffset:Int;
	
	public function new () {
	}
	
}
