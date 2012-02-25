#ifdef GL_ES
// define default precision for float, vec, mat.
precision mediump float;
#endif


attribute vec4 position;
attribute vec4 textureCoordinate;
varying vec2 coordinate;

void main()
{
	gl_Position = position;
	coordinate = textureCoordinate.xy;
}
