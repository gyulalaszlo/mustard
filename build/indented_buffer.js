(function() {
  /*
  IndentedBuffer
  for Mustard and other code generation stuff.
  Copyright © 2011 Gyula László.
  
  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:
  
  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.
  
  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  THE SOFTWARE.
  
  */  var IndentedBuffer, root;
  var __slice = Array.prototype.slice;
  IndentedBuffer = (function() {
    function IndentedBuffer(_indent, buffer) {
      var str, _i, _len;
      this._indent = _indent != null ? _indent : 0;
      if (buffer == null) {
        buffer = [];
      }
      this._buffer = [];
      for (_i = 0, _len = buffer.length; _i < _len; _i++) {
        str = buffer[_i];
        this.push(str);
      }
    }
    IndentedBuffer.prototype.indent = function(str) {
      this._indent += 1;
      if (str !== null) {
        return this.push(str);
      }
    };
    IndentedBuffer.prototype.outdent = function(str) {
      this._indent -= 1;
      if (this._indent < 0) {
        this._indent = 0;
      }
      if (str !== null) {
        return this.push(str);
      }
    };
    IndentedBuffer.prototype.indentString = function(str) {
      var a;
      if (this._indent > 0) {
        a = [];
        a[this._indent - 1] = '';
        return a.join('    ') + str;
      } else {
        return str;
      }
    };
    IndentedBuffer.prototype.push = function() {
      var strs;
      strs = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this._buffer.push(this.indentString.apply(this, strs));
    };
    IndentedBuffer.prototype.join = function(str) {
      if (str == null) {
        str = "\n";
      }
      return this._buffer.join(str);
    };
    IndentedBuffer.prototype.pushMultiLine = function(str) {
      var line, lines, _i, _len, _results;
      lines = str.split(/[\n\r]+/g);
      _results = [];
      for (_i = 0, _len = lines.length; _i < _len; _i++) {
        line = lines[_i];
        _results.push(this.push(line));
      }
      return _results;
    };
    return IndentedBuffer;
  })();
  root = typeof exports !== "undefined" && exports !== null ? exports : this;
  root.IndentedBuffer = IndentedBuffer;
}).call(this);
