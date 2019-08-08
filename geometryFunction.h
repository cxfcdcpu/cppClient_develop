#ifndef GEOMETRYFUNCTION_H
#define GEOMETRYFUNCTION_H
#include <iostream>
#include <string>
#include <unordered_set>
#include <math.h>
#include <sstream>
#include "Point.h"
#include "CycleTrial.h"
#include "HyperTrial.h"
#include "generalFunction.h"


int euDis(int x1,int y1,int x2,int y2);
float findInterTwoCycle(Point,int,Point,int,float);
float findInterHyperCycle(Point,Point,Point, int,int,float,float,vector<float>&);
vector<tuple<float,float>> getRoot(float x0,float y0,float r,float a,float b,vector<float>&);
float rootX(float,float,float);
float hyperArea(float a,float b,tuple<float,float> z1,tuple<float,float> z2);
vector<float> realQudricRoot(float b,float c,float d,float e);
float hyperAreaHelper(float a,float b,float m,float z,float y);

int euDis(int x1, int y1, int x2, int y2)
{
    return (x1-x2)*(x1-x2)+(y1-y2)*(y1-y2);
}

float findInterTwoCycle(Point p1,int h1,Point p2,int h2,float avgHopDis)
{
    const float pi=3.141592653589793;
    float d=sqrt(pDis(p1,p2));
    float A1=0;
    float r1=h1*avgHopDis;
    float r2=h2*avgHopDis;
    float r3=(h1-1)*avgHopDis;
    
    if(d>=r1+r2)return 0;
    else if(r2>=r1+d)return pi*(r1*r1-r3*r3);
    else if(r1>r2+d)A1=pi*r2*r2;
    
    if(A1==0)
    {
      if(d > 0 && r2 > 0 && r3 >0)
        A1=r2*r2*acos((d*d+r2*r2-r1*r1) / (2*d*r2))+r1*r1*acos((d*d+r1*r1-r2*r2) / (2*d*r1))-0.5*sqrt((-d+r2+r1)*(d+r2-r1)*(d-r2+r1)*(d+r1+r2));
      else
        A1=10000;
    }
    
    if (r3==0)return A1;
    float A2=0;
    if(d>=r3+r2)return A1;
    else if(r2>=r3+d)return A1-pi*r3*r3;
    else if(r3>=r2+d)return 0;
    if(d > 0 && r2 > 0 && r3 >0)
        A2=r2*r2*acos((d*d+r2*r2-r3*r3) / (2*d*r2))+r3*r3*acos((d*d+r3*r3-r2*r2) / (2*d*r3))-0.5*sqrt((-d+r2+r3)*(d+r2-r3)*(d-r2+r3)*(d+r3+r2));
    else
        A2=-10000;
    return A1-A2;

}

float findInterHyperCycle(Point h1,Point h2,Point c1,int ah,int h3,float avgHopDis1,float avgHopDis2,vector<float>& yr )
{
  const float pi=3.141592653589793;
  float a = ah*avgHopDis1;
  float r = h3*avgHopDis2;
  float c = sqrt(pDis(h1,h2))/2;
  float b = sqrt( c * c - a * a);
  
  float xs = -(h1.m_X + h2.m_X)/2;
  float ys = -(h1.m_Y + h2.m_Y)/2;
  bool flip = false;
  float ctheta = 1;
  float stheta = 0;
  
  /*
  float stheta = -c*(h2.m_Y+ys)/((h2.m_X+xs)*(h2.m_X+xs)+(h2.m_Y+ys)*(h2.m_Y+ys));
  //not sure if this correct.
  if ( h2.m_Y+ys != 0){
    flip=true;
    ctheta=-(h2.m_X+xs)*stheta/(h2.m_Y+ys);
  }
  */
  //line
  if(h2.m_X+xs==0 && h2.m_Y+ys>0){
    ctheta=0;
    stheta=-1;
  }
  else if(h2.m_X+xs<0 && h2.m_Y+ys==0){
    ctheta=-1;
    stheta=0;
  }
  else if(h2.m_X+xs==0 && h2.m_Y+ys<0){
    ctheta=0;
    stheta=1;
  }
  else if(h2.m_X+xs>0 && h2.m_Y+ys==0){
    ctheta=1;
    stheta=0;
  }
  else {

    ctheta=(h2.m_X+xs)/c;
    stheta=-(h2.m_Y+ys)/c;
  }
              
  float cx=c1.m_X+xs;
  float cy=c1.m_Y+ys;
  float c2x=ctheta*cx-stheta*cy;
  float c2y=stheta*cx+ctheta*cy  ;
  if (abs(a)<5 )
  {
    //cout<<"c2x: "<<c2x<<"; r: "<<r<<endl;
    if(r<abs(c2x))
    {
        yr.push_back(-12345);
        yr.push_back(c2x);
        
        if(c2x>0)return 0;
        else{
         return pi*r*r;
         yr.push_back(pi*r*r);
       }
    }
    else
    {
      //cout<<"0 area: "<<2*acos(c2x/r)<<endl;
      yr.push_back(-100);
      if(flip)yr.push_back(ctheta);
      else yr.push_back(100);
      yr.push_back(c2x);
      float totalArea=acos(c2x/r)*r*r-c2x*sqrt(r*r-c2x*c2x);
      yr.push_back(pi*r*r);
      return totalArea;
    }
  }
  
  vector<tuple<float,float>> rrr = getRoot(c2x, c2y, r, a, b,yr);
  /*
  short count=0;
  cout<<"root numbers: "<<rrr.size()<<endl;
  for( auto& tp : rrr)
  {
     cout<<"root "<<count++<<" is: ("<<get<0>(tp)<<", "<<get<1>(tp)<<")"<<endl;
  
  }
  */
  //handle size=3 later if we have time
  if(rrr.size()>=3)return 400000000;
  
  
  if(rrr.size()<2 && sqrt(pDis(c1,h1))-sqrt(pDis(c1,h2))>2*a)return 0;
  else if(rrr.size()<2 && sqrt(pDis(c1,h1))-sqrt(pDis(c1,h2))<=2*a)return pi*r*r;
  else 
  {
    float area=0;
    
    
        tuple<float,float> z1 = rrr[0];
        tuple<float,float> z2 = rrr[1];
        float i1x = get<0>(z1) - c2x;
        float i1y = get<1>(z1) - c2y;
        float i2x = get<0>(z2) - c2x;
        float i2y = get<1>(z2) - c2y; 
        float sphi = (i1x*i2y-i1y*i2x)/(i1y*i1y+i1x*i1x);
        float cphi = (i2x+i1y*sphi)/i1x*0.999999;
        
        if ((cphi>1 || cphi<-1)&& (1-sphi*sphi>=0))
            cphi=abs(cphi)/cphi*sqrt(1-sphi*sphi);

        float curveArea=hyperArea(a,b,z1,z2);
        if (sphi<0)
            area+=acos(cphi)*r*r/2-abs(sphi)*r*r/2-curveArea;            
        else
            area+=(2*pi-acos(cphi))*r*r/2+abs(sphi)*r*r/2-curveArea;

    return area;
  }
  return 0;
}

vector<tuple<float,float>> getRoot(float x0,float y0,float r,float a,float b,vector<float>& yr)
{
  float aa=a;
  float bb=b;
  float cc=sqrt(a*a+b*b);
  float alph=-2*y0*b*b/(a*a+b*b);
  float beta=(a*a*b*b+x0*x0*b*b+b*b*y0*y0-r*r*b*b)/(a*a+b*b);
  float gama=2*x0*a*b/(a*a+b*b);
  a=1;
  float e=beta*beta-gama*gama*b*b;
  b=2*alph;
  float c=alph*alph+2*beta-gama*gama;
  float d=2*alph*beta;
  
  vector<float> temp = realQudricRoot(b,c,d,e);
  //cout<<"temp size : "<<temp.size()<<endl;
  
  
  vector<tuple<float,float>> res;
  if(!temp.empty()) std::sort(temp.begin(),temp.end());
  float pre=-55555.5;
  float cnt=0;
  for(vector<float>::iterator it=temp.begin();it!=temp.end();it++)
  {
    float y=*it;
    float x=rootX(y,aa,bb);
    
    //cout<<"root y: "<<y<<"; root x: "<<x<<endl;
    //cout<<"cons1: "<<abs(euDis(x,y,x0,y0)-r*r)<< "; cons2: "<<abs(sqrt(euDis(x,y,-cc,0))-sqrt(euDis(x,y,cc,0))-2*aa)<<endl;
    //abs(euDis(x,y,x0,y0)-r*r)<r*150 &&
    if( abs(euDis(x,y,x0,y0)-r*r)<r*r/16 && abs(sqrt(euDis(x,y,-cc,0))-sqrt(euDis(x,y,cc,0))-2*aa)<16 && abs(pre-y) > 5)
    {
      tuple<float,float> curP=make_tuple(x,y);
      cnt+=1;
      res.push_back(curP);
      yr.push_back(y);
      pre=y;
    }
    else
    {
      yr.push_back(abs(euDis(x,y,x0,y0)-r*r));    
    }
    
  }
  return res;
}

float rootX(float y,float a,float b)
{
  return sqrt(b*b+y*y)*a/b; 
}




float hyperArea(float a,float b,tuple<float,float> z1,tuple<float,float> z2)
{
    float z=get<0>(z1)-get<1>(z1)*(get<0>(z2)-get<0>(z1))/(get<1>(z2)-get<1>(z1));
    float m=(get<0>(z2)-get<0>(z1))/(get<1>(z2)-get<1>(z1));
    float y2=get<1>(z2);
    float y1=get<1>(z1);
    return abs(hyperAreaHelper(a,b,m,z,y1)-hyperAreaHelper(a,b,m,z,y2));
}
 
float hyperAreaHelper(float a,float b,float m,float z,float y)
{
    return a/b*(y*sqrt(b*b+y*y)/2 + b*b*log(y+sqrt(b*b+y*y))/2) - m*y*y/2-z*y;
}




vector<float> realQudricRoot(float a, float b, float c, float d)
{
    vector<float> res;
    complex<double>*  solutions = solve_quartic(a, b, c, d);
    for(int i = 0 ; i < 4; i++)
    {
        if(abs(solutions[i].imag())<0.0001)res.push_back(static_cast<float>(solutions[i].real()));
    }
    delete[] solutions;
    return res;
}

#endif