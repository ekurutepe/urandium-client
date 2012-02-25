#ifdef GL_ES
// define default precision for float, vec, mat.
precision mediump float;
#endif

varying vec2 coordinate;
uniform sampler2D videoframe;

uniform float redF;
uniform float greenF;
uniform float blueF;

void main()
{
	vec4 pic = texture2D(videoframe, coordinate);
	float r = pic.r * redF;
	float g = pic.g * greenF;
	float b = pic.b * blueF;
	
	gl_FragColor = vec4(r,g,b,1.0);
}


//
//#ifdef GL_ES
//// define default precision for float, vec, mat.
//precision mediump float;
//#endif
//
//
//uniform sampler2D videoframe; // this should hold the texture rendered by the horizontal blur pass
//varying vec4 coordinate;
// 
//const float blurSize = 3.0/512.0;
//  
//void main(void)
//{
//   vec4 sum = vec4(0.0);
// 
//   // blur in y (vertical)
//   // take nine samples, with the distance blurSize between them
//   sum += texture2D(videoframe, vec2(coordinate.x, coordinate.y - 4.0*blurSize)) * 0.05;
//   sum += texture2D(videoframe, vec2(coordinate.x, coordinate.y - 3.0*blurSize)) * 0.09;
//   sum += texture2D(videoframe, vec2(coordinate.x, coordinate.y - 2.0*blurSize)) * 0.12;
//   sum += texture2D(videoframe, vec2(coordinate.x, coordinate.y - blurSize)) * 0.15;
//   sum += texture2D(videoframe, vec2(coordinate.x, coordinate.y)) * 0.16;
//   sum += texture2D(videoframe, vec2(coordinate.x, coordinate.y + blurSize)) * 0.15;
//   sum += texture2D(videoframe, vec2(coordinate.x, coordinate.y + 2.0*blurSize)) * 0.12;
//   sum += texture2D(videoframe, vec2(coordinate.x, coordinate.y + 3.0*blurSize)) * 0.09;
//   sum += texture2D(videoframe, vec2(coordinate.x, coordinate.y + 4.0*blurSize)) * 0.05;
// 
//   gl_FragColor = sum;
//// gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
////	gl_FragColor = texture2D(videoframe, vec2(coordinate.x, coordinate.y));
//}




