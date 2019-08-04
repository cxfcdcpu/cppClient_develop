#ifndef MY_STRUCT
#define MY_STRUCT
#include <iostream>
#include <string>
#include <unordered_set>
#include <math.h>
#include <sstream>
using namespace std;

struct Point
{
  int m_X;
  int m_Y;

};

struct twoCycleTrial
{
  int c1ID;
  int c2ID; 
  float c1X;
  float c1Y;
  float c2X;
  float c2Y;
  float h1;
  float h2;
  float d;
  float tArea;
  float grAr;
  float rate3;
  float acAr;
};

struct hyperTrial
{
  int c1ID;
  int c2ID;
  int c3ID; 
  float c1X;
  float c1Y;
  float c2X;
  float c2Y;
  float c3X;
  float c3Y;  
  float ah;
  float h3;
  float avgD1;
  float avgD2;
  float tArea;
  float grAr;
  float rate3;
  float acAr;
  float yroot[8];
};

void updateTAS(twoCycleTrial ct, unordered_set<string> & st);
void updateTAS(hyperTrial ht, unordered_set<string> & st);

ostream& operator<<(ostream& os,twoCycleTrial &rhs)
{
  os<<"best two cycle:"<<endl;
  os<<"c1ID: "<<rhs.c1ID<<" coor: ("<<rhs.c1X<<", "<<rhs.c1Y<<")"<<endl;
  os<<"c2ID: "<<rhs.c2ID<<" coor: ("<<rhs.c2X<<", "<<rhs.c2Y<<")"<<endl;
  os<<"r1 and r2 and d: "<<rhs.h1<<"  "<<rhs.h2<<"  "<< rhs.d<< endl;
  os<<"grAr and acAr: "<<rhs.grAr<<"  "<<rhs.acAr<<endl;
  os<<"tArea and rate3: "<<rhs.tArea<< "   "<<rhs.rate3<<endl;
  return os;
}

ostream& operator<<(ostream& os,hyperTrial &rhs)
{
  os<<"best HyperBola and cycle:"<<endl;
  os<<"c1ID: "<<rhs.c1ID<<" coor: ("<<rhs.c1X<<", "<<rhs.c1Y<<")"<<endl;
  os<<"c2ID: "<<rhs.c2ID<<" coor: ("<<rhs.c2X<<", "<<rhs.c2Y<<")"<<endl;
  os<<"c3ID: "<<rhs.c3ID<<" coor: ("<<rhs.c3X<<", "<<rhs.c3Y<<")"<<endl;
  os<<"ah and h3 and avgD1 and avgD2: "<<rhs.ah<<"  "<<rhs.h3<<"  "<< rhs.avgD1<<" "<< rhs.avgD2<< endl;
  os<<"grAr and acAr: "<<rhs.grAr<<"  "<<rhs.acAr<<endl;
  os<<"tArea and rate3: "<<rhs.tArea<< "   "<<rhs.rate3<<endl;
  os<<"roots are: ";
  for(int kk=0;kk<8;kk++)
  {
    os<< rhs.yroot[kk]<< " ";
  }
  os<<endl;
  return os;
}

bool sortCycleTrial(twoCycleTrial ct1, twoCycleTrial ct2)
{
  return ct1.grAr * ct1 . rate3 > ct2 . grAr * ct2 . rate3;

}

bool sortHyperTrial(hyperTrial ct1, hyperTrial ct2)
{
  return  ct1.grAr * ct1 . rate3 > ct2 . grAr * ct2 . rate3;

}

string findBestTry(twoCycleTrial * cTri, hyperTrial * hTri, int cs, int hs, unordered_set<string> & TAS)
{
    string res="";
    int maxInd=0;
    float max1=0;
    for(int k=0;k<cs;k++)
    {
        if(max1<cTri[k].grAr){
          max1=cTri[k].grAr;
          maxInd=k;
        }
    }
    

    int maxInd2=0;
    float max2=0;
    for(int k=0;k<hs;k++)
    {
        if(max2<hTri[k].grAr){
          max2=hTri[k].grAr;
          maxInd2=k;
        }
    }
    
    if(max1>=max2)
    {
        cout<<cTri[maxInd]<<endl;
        
        updateTAS(cTri[maxInd],TAS);
        
        res+="\n(";
        res+=to_string(cTri[maxInd].c1ID);
        res+="; ";
        res+=to_string(cTri[maxInd].c2ID);
        res+="; ";
        res+=to_string(cTri[maxInd].h1);
        res+="; ";
        res+=to_string(cTri[maxInd].h2);
        res+="; ";
        res+=to_string(cTri[maxInd].d);
        res+=")";
    
    }
    else
    {
        cout<<hTri[maxInd2]<<endl;
        updateTAS(hTri[maxInd2],TAS);
        res+="\n(";
        res+=to_string(hTri[maxInd2].c1ID);
        res+="; ";
        res+=to_string(hTri[maxInd2].c2ID);
        res+="; ";
        res+=to_string(hTri[maxInd2].c3ID);
        res+="; ";
        res+=to_string(hTri[maxInd2].ah);
        res+="; ";
        res+=to_string(hTri[maxInd2].h3);
        res+="; ";
        res+=to_string(hTri[maxInd2].avgD1);
        res+="; ";
        res+=to_string(hTri[maxInd2].avgD2);
        res+=")";
    }
    
            /*
     Point h1;
     Point h2;
     Point c1;
     int ah, h3;
     float avgHopDis1;
     float avgHopDis2;
     float suppose;
     //string temp;
     //getline(cin,temp);
     //stringstream ttt(temp);
     h1.m_X=curUser.getX(hTri[maxInd].c1ID);
     h1.m_Y=curUser.getY(hTri[maxInd].c1ID);   
     h2.m_X=curUser.getX(hTri[maxInd].c2ID);
     h2.m_Y=curUser.getY(hTri[maxInd].c2ID);
     c1.m_X=curUser.getX(hTri[maxInd].c3ID); 
     c1.m_Y=curUser.getY(hTri[maxInd].c3ID);
     ah=hTri[maxInd].ah;
     h3=hTri[maxInd].h3;
     avgHopDis1=hTri[maxInd].avgD1;
     avgHopDis2=hTri[maxInd].avgD2;     
     suppose=hTri[maxInd].tArea; 
     vector<float> f1;
     vector<float> f2;
     
        float area1 = findInterHyperCycle(h1,h2,c1,ah,h3,avgHopDis1,avgHopDis2,f1);
        float area2 = findInterHyperCycle(h1,h2,c1,(ah-1),h3,avgHopDis1,avgHopDis2,f2);
        cout<<"area1: "<<area1<<"; area2: "<<area2<<endl;
        cout<<"total area: "<<area1-area2<<" suppose: "<<suppose<<endl;
        cout<<"roots are: ";
        for(int kk=0;kk<8;kk++)
        {
          cout<< hTri[maxInd].yroot[kk]<< " ";
        }
        cout<<endl;
       */ 
    return res;
}

void updateTAS(twoCycleTrial ct, unordered_set<string> & TAS)
{
  vector<string> temp;
  for(string st : TAS)
  {
    stringstream ss(st);
    float i,j;
    ss>>i;
    ss>>j;
    //<<i<<endl;
    float di1=ct.c1X-i;
    float dj1=ct.c1Y-j;
    float di2=ct.c2X-i;
    float dj2=ct.c2Y-j;
    float rr1 = ct.h1*ct.d*ct.h1*ct.d;
    float rr2 = ct.h2*ct.d*ct.h2*ct.d;
    float rr3 = (ct.h1-1)*ct.d*(ct.h1-1)*ct.d;
    
    if (di1*di1+dj1*dj1<=rr1 && di1*di1+dj1*dj1>rr3 && di2*di2+dj2*dj2<=rr2)
    {
      //cout<<"erasing cycle tas"<<endl;
      temp.push_back(st);
    }
  }
  for(string st : temp)
  {
      TAS.erase(st);
  }
}
  
void updateTAS(hyperTrial ct, unordered_set<string> & TAS)
{
  vector<string> temp;
  for(string st : TAS)
  {
    stringstream ss(st);
    float i,j;
    ss>>i;
    ss>>j;
    //cout<<j<<endl;
    float tt = sqrt((i-ct.c1X)*(i-ct.c1X)+(j-ct.c1Y)*(j-ct.c1Y))-sqrt((i-ct.c2X)*(i-ct.c2X)+(j-ct.c2Y)*(j-ct.c2Y));
    float di=ct.c3X-i;
    float dj=ct.c3Y-j;
    float rr = ct.h3*ct.avgD2*ct.h3*ct.avgD2;
    float a = ct.ah * ct.avgD1;
    float a2 = (ct.ah-1.0)*ct.avgD1;
    
    if(di * di + dj * dj <= rr && tt <= 2*a && tt >= 2* a2)
    {
      //cout<<"erasing hyper tas"<<endl;
      temp.push_back(st);
    }
  }
  for(string st : temp)
  {
    TAS.erase(st);
  }
}

#endif