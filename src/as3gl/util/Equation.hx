/**
 * Parses an implicit string equation with n variables.
 * 
 * Variable format:
 * x0 First variable
 * x1 Second variable
 * ...
 * xn nth variable
 * r generated random variable
 * 
 * Number format:
 * Any floating point number.
 * 
 * Constants:
 * PI
 * 
 * Allowed binary operations include:
 * + Addition
 * - Subtraction
 * * Multiplication
 * / Division
 * 
 * Allowed functions include:
 * sin(Expr)
 * cos(Expr)
 * tan(Expr)
 * sqrt(Expr)
 * hs(Expr) - Heaviside function (0 iff Expr < 0, 1 iff Expr >= 0)
 * 
 * Other syntax:
 * () Brackets
 * 
 * eg) hs(5 + sin(4)) / (-4 + x0*x1)
 * 
 * @author Sam MacPherson
 */

package as3gl.util;

import de.polygonal.core.math.Mathematics;
import flash.display.Loader;
import flash.errors.Error;
import flash.events.Event;
import haxe.io.Bytes;
import haxe.io.BytesOutput;

class Equation {
	
	private static var _NEXT_CLASS_ID:Int = 0;
	
	private static var _variable:EReg = ~/^(x[0-9]+)/;
	private static var _number:EReg = ~/^(-{0,1}[0-9]+\.{0,1}[0-9]*)/;
	private static var _add:EReg = ~/^(\+)/;
	private static var _sub:EReg = ~/^(\-)/;
	private static var _mult:EReg = ~/^(\*)/;
	private static var _div:EReg = ~/^(\/)/;
	private static var _lparen:EReg = ~/^(\()/;
	private static var _rparen:EReg = ~/^(\))/;
	private static var _rand:EReg = ~/^(r)/i;
	private static var _pi:EReg = ~/^(pi)/i;
	private static var _sin:EReg = ~/^(sin\()/i;
	private static var _cos:EReg = ~/^(cos\()/i;
	private static var _tan:EReg = ~/^(tan\()/i;
	private static var _sqrt:EReg = ~/^(sqrt\()/i;
	private static var _hs:EReg = ~/^(hs\()/i;
	
	private var _index:Int;
	private var _tokens:Array<Token>;

	private function new (tokens:Array<Token>) {
		_tokens = tokens;
	}
	
	public static inline function compile (eq:String):Equation {
		return new Equation(_lex(StringTools.trim(eq)));
	}
	
	private static inline function _lex (eq:String):Array<Token> {
		var tokens:Array<Token> = new Array<Token>();
		var s:String = eq;
		while (s.length > 0) {
			var str:String = null;
			if (_variable.match(s)) {
				str = _variable.matched(1);
				var val:Int = Std.parseInt(str.substr(1));
				tokens.push(new VariableToken(str, val));
			} else if (_sub.match(s) && tokens.length > 0 && (Std.is(tokens[tokens.length - 1], ValueTerminalToken) || Std.is(tokens[tokens.length - 1], RightParenToken))) {
				str = _sub.matched(1);
				tokens.push(new SubtractToken(str));
			} else if (_number.match(s)) {
				str = _number.matched(1);
				var val:Float = Std.parseFloat(str);
				tokens.push(new NumberToken(str, val));
			} else if (_add.match(s)) {
				str = _add.matched(1);
				tokens.push(new AddToken(str));
			} else if (_mult.match(s)) {
				str = _mult.matched(1);
				tokens.push(new MultiplyToken(str));
			} else if (_div.match(s)) {
				str = _div.matched(1);
				tokens.push(new DivideToken(str));
			} else if (_lparen.match(s)) {
				str = _lparen.matched(1);
				tokens.push(new LeftParenToken(str));
			} else if (_rparen.match(s)) {
				str = _rparen.matched(1);
				tokens.push(new RightParenToken(str));
			} else if (_rand.match(s)) {
				str = _rand.matched(1);
				tokens.push(new RandomToken(str));
			} else if (_pi.match(s)) {
				str = _pi.matched(1);
				tokens.push(new NumberToken(str, Math.PI));
			} else if (_sin.match(s)) {
				str = _sin.matched(1);
				tokens.push(new SinToken(str));
			} else if (_cos.match(s)) {
				str = _cos.matched(1);
				tokens.push(new CosToken(str));
			} else if (_tan.match(s)) {
				str = _tan.matched(1);
				tokens.push(new TanToken(str));
			} else if (_sqrt.match(s)) {
				str = _sqrt.matched(1);
				tokens.push(new SqrtToken(str));
			} else if (_hs.match(s)) {
				str = _hs.matched(1);
				tokens.push(new HeavisideToken(str));
			} else {
				throw new Error("Unknown token at '" + s + "'.");
			}
			s = StringTools.ltrim(s.substr(str.length));
		}
		
		return tokens;
	}
	
	/*private inline static _compile (tokens:Array<Token>):Void {
		//Write ABC
		var context:Context = new Context();
		var tfloat = context.type("Number");
		var tarr = context.type("Array");
		context.beginClass("Equation_" + (_NEXT_CLASS_ID++));
		var m = context.beginMethod("compute", [tarr], tfloat);
		m.maxStack = 1;
		//context.ops(_expr(tokens));
		context.ops([
			OInt(667),
			ORet,
		]);
		context.finalize();
		
		//Compile ABC
		var abcOutput = new BytesOutput();
		format.abc.Writer.write(abcOutput, context.getData());
		var abc:Bytes = abcOutput.getBytes();
		
		//Create SWF
		var swfOutput:haxe.io.BytesOutput = new haxe.io.BytesOutput();
		var swfFile:SWF = {
			header: {
				version: 9,
				compressed: false,
				width: 400,
				height: 300,
				fps: cast(30, Float),
				nframes: 1
			},
			tags: [
				TSandBox(25),
				TActionScript3(abc),
				TShowFrame
            ]
        }
		
		//Write SWF
		var writer:format.swf.Writer = new format.swf.Writer(swfOutput);
		writer.write(swfFile);
		var swf:Bytes = swfOutput.getBytes();
		
		//Load swf
		var loader:Loader = new Loader();
		loader.contentLoaderInfo.addEventListener(Event.COMPLETE, _onComplete);
		loader.loadBytes(swf.getData());
	}
	
	private static function _onComplete (e:Event):Void {
		e.target.removeEventListener(Event.COMPLETE, _onComplete);
		var cid:Int = e.target.loader.cid;
		var cls = loader.contentLoaderInfo.applicationDomain.getDefinition("Equation_" + cid);
        var inst:Dynamic = Type.createInstance(cls, []);
		inst.compute();
	}*/
	
	public function isConstant ():Bool {
		for (i in _tokens) {
			if (Std.is(i, VariableToken)) return false;
			else if (Std.is(i, RandomToken)) return false;
		}
		return true;
	}
	
	public function compute (input:Array<Float>):Float {
		_index = 0;
		return _expr(input);
	}
	
	private inline function _err (token:Token):Void {
		throw new Error("Syntax error at token '" + token.str + "'.");
	}
	
	private inline function _eoi ():Bool {
		return _index >= _tokens.length;
	}
	
	private function _expr (input:Array<Float>):Float {
		var token:Token = _tokens[_index];
		if (Std.is(token, ValueTerminalToken) || Std.is(token, FunctionToken)) {
			return _term(input);
		} else {
			_err(token);
			return Mathematics.NaN;
		}
	}
	
	private function _term (input:Array<Float>):Float {
		var token:Token = _tokens[_index];
		if (Std.is(token, ValueTerminalToken) || Std.is(token, FunctionToken)) {
			return _moreTerm(_factor(input), input);
		} else {
			_err(token);
			return Mathematics.NaN;
		}
	}
	
	private function _moreTerm (left:Float, input:Array<Float>):Float {
		var token:Token = _tokens[_index];
		if (Std.is(token, AddToken)) {
			_index++;
			return left + _term(input);
		} else if (Std.is(token, SubtractToken)) {
			_index++;
			return left - _term(input);
		} else if (Std.is(token, RightParenToken) || _eoi()) {
			return left;
		} else {
			_err(token);
			return Mathematics.NaN;
		}
	}
	
	private function _factor (input:Array<Float>):Float {
		var token:Token = _tokens[_index];
		if (Std.is(token, ValueTerminalToken)) {
			return _moreFactor(_val(input), input);
		} else if (Std.is(token, LeftParenToken)) {
			_index++;
			var v:Float = _expr(input);
			if (!Std.is(_tokens[_index++], RightParenToken)) {
				_err(token);
				return Mathematics.NaN;
			}
			return _moreFactor(v, input);
		} else if (Std.is(token, SinToken)) {
			_index++;
			var v:Float = Math.sin(_expr(input));
			if (!Std.is(_tokens[_index++], RightParenToken)) {
				_err(token);
				return Mathematics.NaN;
			}
			return _moreFactor(v, input);
		} else if (Std.is(token, CosToken)) {
			_index++;
			var v:Float = Math.cos(_expr(input));
			if (!Std.is(_tokens[_index++], RightParenToken)) {
				_err(token);
				return Mathematics.NaN;
			}
			return _moreFactor(v, input);
		} else if (Std.is(token, TanToken)) {
			_index++;
			var v:Float = Math.tan(_expr(input));
			if (!Std.is(_tokens[_index++], RightParenToken)) {
				_err(token);
				return Mathematics.NaN;
			}
			return _moreFactor(v, input);
		} else if (Std.is(token, SqrtToken)) {
			_index++;
			var v:Float = Math.sqrt(_expr(input));
			if (!Std.is(_tokens[_index++], RightParenToken)) {
				_err(token);
				return Mathematics.NaN;
			}
			return _moreFactor(v, input);
		} else if (Std.is(token, HeavisideToken)) {
			_index++;
			var v:Float = if (_expr(input) >= 0) 1 else 0;
			if (!Std.is(_tokens[_index++], RightParenToken)) {
				_err(token);
				return Mathematics.NaN;
			}
			return _moreFactor(v, input);
		} else {
			_err(token);
			return Mathematics.NaN;
		}
	}
	
	private function _moreFactor (left:Float, input:Array<Float>):Float {
		var token:Token = _tokens[_index];
		if (Std.is(token, MultiplyToken)) {
			_index++;
			return left * _factor(input);
		} else if (Std.is(token, DivideToken)) {
			_index++;
			return left / _factor(input);
		} else if (Std.is(token, AddToken) || Std.is(token, SubtractToken) || Std.is(token, RightParenToken) || _eoi()) {
			return left;
		} else {
			_err(token);
			return Mathematics.NaN;
		}
	}
	
	private function _val (input:Array<Float>):Float {
		var token:Token = _tokens[_index];
		if (Std.is(token, VariableToken)) {
			_index++;
			return input[Std.int(cast(token, VariableToken).val)];
		} else if (Std.is(token, NumberToken)) {
			_index++;
			return cast(token, NumberToken).val;
		} else if (Std.is(token, RandomToken)) {
			_index++;
			return Math.random();
		} else {
			_err(token);
			return Mathematics.NaN;
		}
	}
	
}

private class EquationLoader extends Loader {
	
	public var cid:Int;
	
	public function new (cid:Int) {
		super();
		
		this.cid = cid;
	}
	
}

//Token classes

private class Token {
	
	public var str:String;
	
	public function new (str:String) {
		this.str = str;
	}
	
}

private class ValueTerminalToken extends Token {
	
	public var val:Float;
	
	public function new (str:String, val:Float) {
		super(str);
		this.val = val;
	}
	
}

private class VariableToken extends ValueTerminalToken {
	
	public function new (str:String, index:Int) {
		super(str, index);
	}
	
}

private class NumberToken extends ValueTerminalToken {
	
	public function new (str:String, val:Float) {
		super(str, val);
	}
	
}

private class RandomToken extends ValueTerminalToken {
	
	public function new (str:String) {
		super(str, 0);
	}
	
}

private class BinaryOperatorToken extends Token {
	
	public function new (str:String) {
		super(str);
	}
	
}

private class AddToken extends BinaryOperatorToken {
	
	public function new (str:String) {
		super(str);
	}
	
}

private class SubtractToken extends BinaryOperatorToken {
	
	public function new (str:String) {
		super(str);
	}
	
}

private class MultiplyToken extends BinaryOperatorToken {
	
	public function new (str:String) {
		super(str);
	}
	
}

private class DivideToken extends BinaryOperatorToken {
	
	public function new (str:String) {
		super(str);
	}
	
}

private class FunctionToken extends Token {
	
	public function new (str:String) {
		super(str);
	}
	
}

private class LeftParenToken extends FunctionToken {
	
	public function new (str:String) {
		super(str);
	}
	
}

private class RightParenToken extends Token {
	
	public function new (str:String) {
		super(str);
	}
	
}

private class SinToken extends FunctionToken {
	
	public function new (str:String) {
		super(str);
	}
	
}

private class CosToken extends FunctionToken {
	
	public function new (str:String) {
		super(str);
	}
	
}

private class TanToken extends FunctionToken {
	
	public function new (str:String) {
		super(str);
	}
	
}

private class SqrtToken extends FunctionToken {
	
	public function new (str:String) {
		super(str);
	}
	
}

private class HeavisideToken extends FunctionToken {
	
	public function new (str:String) {
		super(str);
	}
	
}