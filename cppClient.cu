/**
	C++ client example using sockets
*/
#include<iostream>	//cout
#include<stdio.h>	//printf
#include<string.h>	//strlen
#include<string>	//string
#include<cstring>
#include<sys/socket.h>	//socket
#include<arpa/inet.h>	//inet_addr
#include<netdb.h>	//hostent
#include<stdlib.h>
#include <unistd.h>
#include <thread>
#include <chrono> 
#include "safeQueue.h"
#include "quartic.h"
#include <map>
#include <sstream> 
#include <iterator>
#include <unordered_set>
#include <vector>
#include <math.h>
#include <future>
#include <complex>
#include <algorithm>
#include "myStruct.h"
using namespace std;

/**
	TCP Client class
*/
Queue<int> intQueue;
Queue<string> stringQueue;
Queue<string> computingQueue;
const int nodeSize=5001;
const int strokeSize=5000;
const int anchorSize=200;
const int width = 1500;
const int height = 1000;


class tcp_client
{
private:
	int sock;
	std::string address;
	int port;
	struct sockaddr_in server;
	
public:
	tcp_client();
	bool conn(string, int);
	bool send_data(string data);

	void receive(char buf[]);
};

class User
{
  
  private:
    string id;
    int nodes;
    int anchor;
    int radioRange;
    int epoch;
    int tSize;
    short xList[nodeSize];
    short yList[nodeSize];
    short tx[strokeSize];
    short ty[strokeSize];
    //int hv[nodeSize][anchorSize];
    bool computingLock;
    int totalStroke;
    
  public:
    unordered_set<string> TAS;
    map<string,string> resultMap;
    User():xList(),yList()
    {
        id="none";
        nodes=-1;
        anchor=-1;
        radioRange=-1;
        epoch=-1;
        tSize=0;
        computingLock=0;
        for(int i=0;i<strokeSize;i++)
        {
          tx[i]=-1;
          ty[i]=-1;
        }
        for(int i=0;i<nodeSize;i++)
        {
          xList[i]=rand()%width;
          yList[i]=rand()%height;
        }
    
    }
    User(string i):xList(),yList()
    {
        id=i;
        epoch=-1;
        nodes=-1;
        anchor=-1;
        radioRange=-1;
        tSize=0;
        computingLock=0;
        for(int i=0;i<strokeSize;i++)
        {
          tx[i]=-1;
          ty[i]=-1;
        }
        for(int i=0;i<nodeSize;i++)
        {
          xList[i]=rand()%width;
          yList[i]=rand()%height;
        }
    }
    void setNodes(int n){nodes=n;}
    void setAnchor(int a){anchor=a;}
    void setRange(int r){radioRange=r;}
    void setEpoch(int e){epoch=e;}
    void setX(int i, int v){xList[i]=v;}
    void setY(int i, int v){yList[i]=v;}
    void setTraj(int x, int y, int ind){tx[ind]=x;ty[ind]=y;}
    int getNodes(){return nodes;}
    int getAnchor(){return anchor;}
    int getRange(){return radioRange;}
    int getEpoch(){return epoch;}
    int getX(int i){return xList[i];}
    int getY(int i){return yList[i];}
    void genTAS(int totalStroke);
    void addToTAS(Point p, int width);
    void addToTAS(Point p1, Point p2, int width);
    void printArea();
    vector<twoCycleTrial> findTwoCycleTrial(short hv[][anchorSize]);
    vector<hyperTrial> findHyperTrial(short hv[][anchorSize]);
    vector<hyperTrial> hyperHelper(short hv[][anchorSize], int, int);
    
    void getHopInfo(short hv[][anchorSize]);
    //void updataHopVector();
};

const int userSize=10000;
map<string,int> indexMap;

User allUser[userSize];
string idList[userSize];

int userNow=-1;


int myStoi(string data);
void addData(string data);
int getUser(string tmpID);
void setupUser(string tmpID,int epoch,int nodeNum,int anchorNum,int radioRange);
void configNodes(string tmpID,int epoch,int nodeID,int X,int Y);
void addTrajectory(string tmpID,int epoch,int traInd,int X,int Y);
void setupTAS(string tmpID,int epoch, string requestID,int totalStroke);
int pDis(Point p1, Point p2);
int lDis(Point p1, Point p2, Point p3);
int euDis(int x1,int y1,int x2,int y2);
float findInterTwoCycle(Point,int,Point,int,float);
float findInterHyperCycle(Point,Point,Point, int,int,float,float,vector<float>&);
vector<tuple<float,float>> getRoot(float x0,float y0,float r,float a,float b,vector<float>&);
float rootX(float,float,float);
float hyperArea(float a,float b,tuple<float,float> z1,tuple<float,float> z2);
vector<float> realQudricRoot(float b,float c,float d,float e);
float hyperAreaHelper(float a,float b,float m,float z,float y);


tcp_client::tcp_client()
{
	sock = -1;
	port = 0;
	address = "";
}

void User:: printArea()
{
    cout<<"printing TAS"<<endl;
    int counter=0;
    for(string point: TAS)
    {
        counter++;
        cout<<"("<<point<<");";
    }
    cout<<endl;
    cout<<"total: "<<counter<<" points"<<endl;
    


}


vector<hyperTrial> User::findHyperTrial(short hv[][anchorSize])
{

    vector<hyperTrial> trials;
    
    vector<future<vector<hyperTrial>>> VF;
    for(int i=1;i<=12;i++)
    {
      for(int j=1;j<=10;j++)
      {
        VF.push_back(async(&User::hyperHelper,this,hv,j,i));
      }
    }
    
    for(auto& V:VF)
    {
      vector<hyperTrial> curT = V.get();
      //cout<<"Threads results number: "<<curT.size()<<endl;
      for(vector<hyperTrial>::iterator it = curT.begin();it != curT.end();++it)
      {
        trials.push_back(*it);
      }
    }
    
    return trials;
}


vector<EllipseTrial> User::findEllipseTrial(short hv[][anchorSize])
{

    vector<EllipseTrial> trials;
    
    vector<future<vector<EllipseTrial>>> VF;
    for(int i=1;i<=12;i++)
    {
      for(int j=1;j<=10;j++)
      {
        VF.push_back(async(&User::ellipseHelper,this,hv,j,i));
      }
    }
    
    for(auto& V:VF)
    {
      vector<EllipseTrial> curT = V.get();
      //cout<<"Threads results number: "<<curT.size()<<endl;
      for(vector<EllipseTrial>::iterator it = curT.begin();it != curT.end();++it)
      {
        trials.push_back(*it);
      }
    }
    
    return trials;
}


void User :: getHopInfo(short hv[][anchorSize])
{
    nodes = nodes < 5000 ? nodes : 5000; 
    nodes = nodes < 0 ? 5000 : nodes;
    vector<vector<int>> neighborsList(nodes);
    
    for(int i=0;i<nodes;i++)
    {
        int curX=xList[i];
        int curY=yList[i];
        
        for(int j=0;j<nodes;j++)
        {
            if(i!=j){
                int neighborX=xList[j];
                int neighborY=yList[j];
                if(euDis(curX,curY,neighborX,neighborY)<radioRange*radioRange)
                {
                    neighborsList[i].push_back(j);
                }
            }
        }
    }
    
    //cout<<radioRange<<endl;
    
    
    for(int i=0;i<nodes;i++)
    {
        for(int j=0;j<anchor;j++)
        {
            hv[i][j]=-1;
        }
    }
    
    for(int i=0;i<anchor;i++)
    {
        unordered_set<int> visited;
        queue<int> nq;
        nq.push(i);
        while(!nq.empty())
        {
            int cur=nq.front();
            nq.pop();
            visited.insert(cur);
            int curHop=hv[cur][i]==-1?0:hv[cur][i];
          if(!neighborsList[cur].empty()){
            for(int neighbor : neighborsList[cur])
            {
                if(visited.find(neighbor)==visited.end())
                {
                    nq.push(neighbor);
                    visited.insert(neighbor); 
                }
                if(hv[neighbor][i]==-1)hv[neighbor][i]=curHop+1;
                else
                {
                    hv[neighbor][i]=hv[neighbor][i]<curHop+1?hv[neighbor][i]:curHop+1;
                }  
            }
          }
      }
    }

}

vector<twoCycleTrial> User::findTwoCycleTrial(short hv[][anchorSize])
{

    vector<twoCycleTrial> trials;

    for(int i=0;i<anchor;i++)
    {
      for(int j=0;j<anchor;j++)
      {
      if(i!=j){
        float avgHopDis= radioRange;
        float dis=sqrt(euDis(xList[i],yList[i],xList[j],yList[j]));
        Point p1={xList[i],yList[i]};
        Point p2={xList[j],yList[j]};
        //cout<<i<<" and "<<j<<" hv: "<<hv[i][j]<<" dis "<<dis<<endl;
        if(hv[i][j]!=-1&&hv[i][j]!=0)avgHopDis=dis / hv[i][j];
      
        //cout<<"avgHopDis: "<<avgHopDis<<endl;
        for(int h1=1;h1<20;h1++)
        {
          for(int h2=1;h2<20;h2++)
          {
            if ( (h1+h2)*avgHopDis>dis)
            {
                float area=findInterTwoCycle(p1,h1,p2,h2,avgHopDis);
                if (area>1000)
                {
                    twoCycleTrial tryEntry={i,j,static_cast<float>(xList[i]),static_cast<float>(yList[i]),
                                        static_cast<float>(xList[j]),static_cast<float>(yList[j]),static_cast<float>(h1),
                                        static_cast<float>(h2),static_cast<float>(avgHopDis),static_cast<float>(area),0,0,0};  
                    trials.push_back(tryEntry);
                }
            }
          
          }
        }
       }
      }
    }
    return trials;
}

vector<ellipseTrial> User::ellipseHelper(short hv[][anchorSize],int  ah,int  h3)
{
    vector<ellipseTrial> trials;

    for(int i=0;i<anchor;i++)
    {
      for(int j=0;j<anchor;j++)
      {
        if(i!=j)
	      {
          float avgHopDis1= radioRange;
          float avgHopDis2= radioRange;
          float dis=sqrt(euDis(xList[i],yList[i],xList[j],yList[j]));
          Point p1={xList[i],yList[i]};
          Point p2={xList[j],yList[j]};
          if(hv[i][j]!=-1&&hv[i][j]!=0)avgHopDis1=(dis + radioRange/3) / hv[i][j];
          for(int z=0;z<anchor;z++)
          {
            //cout<<"Thread is working"<<endl;
            Point p3={xList[z],yList[z]};
            float dis2=sqrt(euDis(xList[z],yList[z],xList[j],yList[j]));
            float dis3=sqrt(euDis(xList[z],yList[z],xList[i],yList[i]));
            if(hv[z][j]!=-1&&hv[z][j]!=0 && hv[z][i]!=-1&&hv[z][i]!=0)
            {
	            avgHopDis2=(dis+ dis2 +dis3+radioRange) / (hv[i][j]+hv[z][j]+hv[z][i]);
	            //cout<<"avgHopDis2: "<<avgHopDis2<<endl;
	            vector<float> yr1;
	            vector<float> yr2;
	            float area1 = findInterEllipseCycle(p1,p2,p3,ah,h3,avgHopDis1,avgHopDis2,yr1);
	            float area2 = findInterEllipseCycle(p1,p2,p3,(ah-1),h3,avgHopDis1,avgHopDis2,yr2);
	            
	            //cout<<"area1 is : "<< area1<<endl;
	            //cout<<"area2 is : "<< area2<<endl;
	        
	            if(area1-area2>1000 && area1-area2 < 640000)
	            {
	              float yroot[8]={0.0};
	              int startInd=0;
	              for(float& y1:yr1)
	              {
	                yroot[startInd++]=y1;
	              }
	              startInd=4;
	              for(float& y2:yr2)
	              {
	                yroot[startInd++]=y2;
	              }
	              ellipseTrial tryEntry={i,j,z,static_cast<float>(xList[i]),static_cast<float>(yList[i]),
	                                static_cast<float>(xList[j]),static_cast<float>(yList[j]),static_cast<float>(xList[z]),
	                                static_cast<float>(yList[z]),static_cast<float>(ah),static_cast<float>(h3),
	                                static_cast<float>(avgHopDis1),static_cast<float>(avgHopDis2),
	                                static_cast<float>(area1-area2),0,0,0};
	              memcpy(&(tryEntry.yroot), &yroot, 32) ;    
	              trials.push_back(tryEntry);
	            }
            }
          }
          
        }
      }
    }
    //cout<<"trials size: "<<trials.size()<<endl;
    return trials;
}

vector<hyperTrial> User::hyperHelper(short hv[][anchorSize],int  ah,int  h3)
{
    vector<hyperTrial> trials;

    for(int i=0;i<anchor;i++)
    {
      for(int j=0;j<anchor;j++)
      {
        if(i!=j){
          float avgHopDis1= radioRange;
          float avgHopDis2= radioRange;
          float dis=sqrt(euDis(xList[i],yList[i],xList[j],yList[j]));
          Point p1={xList[i],yList[i]};
          Point p2={xList[j],yList[j]};
          if(hv[i][j]!=-1&&hv[i][j]!=0)avgHopDis1=dis / hv[i][j];
          //avgHopDis2= avgHopDis1;
          if(dis>2*ah*avgHopDis1)
          {
            for(int z=0;z<anchor;z++)
            {
              //cout<<"Thread is working"<<endl;
              Point p3={xList[z],yList[z]};
              float dis2=sqrt(euDis(xList[z],yList[z],xList[j],yList[j]));
              float dis3=sqrt(euDis(xList[z],yList[z],xList[i],yList[i]));
              if(hv[z][j]!=-1&&hv[z][j]!=0 && hv[z][i]!=-1&&hv[z][i]!=0)
              {
                  avgHopDis2=(dis+ dis2 +dis3) / (hv[i][j]+hv[z][j]+hv[z][i]);
                  //cout<<"avgHopDis2: "<<avgHopDis2<<endl;
                  vector<float> yr1;
                  vector<float> yr2;
                  float area1 = findInterHyperCycle(p1,p2,p3,ah,h3,avgHopDis1,avgHopDis2,yr1);
                  float area2 = findInterHyperCycle(p1,p2,p3,(ah-1),h3,avgHopDis1,avgHopDis2,yr2);
                  
                  //cout<<"area1 is : "<< area1<<endl;
                  //cout<<"area2 is : "<< area2<<endl;
                  
                  if(area1-area2>1000 && area1-area2 < 640000){
                    float yroot[8]={0.0};
                    int startInd=0;
                    for(float& y1:yr1)
                    {
                      yroot[startInd++]=y1;
                    }
                    startInd=4;
                    for(float& y2:yr2)
                    {
                      yroot[startInd++]=y2;
                    }
                    hyperTrial tryEntry={i,j,z,static_cast<float>(xList[i]),static_cast<float>(yList[i]),
                                      static_cast<float>(xList[j]),static_cast<float>(yList[j]),static_cast<float>(xList[z]),
                                      static_cast<float>(yList[z]),static_cast<float>(ah),static_cast<float>(h3),
                                      static_cast<float>(avgHopDis1),static_cast<float>(avgHopDis2),
                                      static_cast<float>(area1-area2),0,0,0};
                    memcpy(&(tryEntry.yroot), &yroot, 32) ;    
                    trials.push_back(tryEntry);
                  }
              }
            }
          }
        }
      }
    }
    //cout<<"trials size: "<<trials.size()<<endl;
    return trials;
}

__global__ void goOver2(int n, hyperTrial *data, float *area,int m){
    int index = threadIdx.x+blockIdx.x*blockDim.x;
    int stride=blockDim.x*gridDim.x;
    for(int k=index;k<n;k+=stride){
        float x = data[k].c3X;
        float y = data[k].c3Y;
        float r = data[k].h3 * data[k].avgD2;
        float a = data[k].ah * data[k].avgD1;
        
        float h1x = data[k].c1X;
        float h1y = data[k].c1Y;
        float h2x = data[k].c2X;
        float h2y = data[k].c2Y;
        
        float rr = r*r;
        float a2 = (data[k].ah-1.0)*data[k].avgD1;
        float total =0.0;
        
        for(int l = 0; l<m;){
            float i = area[l++];
            float j = area[l++];
            float tt = sqrtf((i-h1x)*(i-h1x)+(j-h1y)*(j-h1y))-sqrtf((i-h2x)*(i-h2x)+(j-h2y)*(j-h2y));
            float di = x-i;
            float dj = y-j;
            if(di * di + dj * dj <= rr && tt <= 2*a && tt >= 2* a2) total+=1.0;
        }

        float rate3 = data[k].rate3;
        data[k].grAr=rate3*total;
        data[k].acAr = total;

    }
}

__global__ void bestHyper(int n, hyperTrial *data, float *area,int m){
    int index = threadIdx.x+blockIdx.x*blockDim.x;
    int stride=blockDim.x*gridDim.x;
    for(int k=index;k<n;k+=stride){
        float x = data[k].c3X;
        float y = data[k].c3Y;
        float r = data[k].h3 * data[k].avgD2;
        float a = data[k].ah * data[k].avgD1;
        
        float h1x = data[k].c1X;
        float h1y = data[k].c1Y;
        float h2x = data[k].c2X;
        float h2y = data[k].c2Y;
        
        float rr = r*r;
        float a2 = (data[k].ah-1.0)*data[k].avgD1;
        float total =0.0;
        
        for(int l = 0; l<m;){
            float i = area[l++];
            float j = area[l++];
            float tt = sqrtf((i-h1x)*(i-h1x)+(j-h1y)*(j-h1y))-sqrtf((i-h2x)*(i-h2x)+(j-h2y)*(j-h2y));
            float di = x-i;
            float dj = y-j;
            if(di * di + dj * dj <= rr && tt <= 2*a && tt >= 2* a2) total+=1.0;
        }
        float rate = total / (data[k].tArea +0.1);
        float rate3 = rate*rate*rate;
        if ( rate3<1.1){
            data[k].grAr=rate3*total;
            data[k].acAr = total;
            data[k].rate3 = rate3;
        }
    }
}

__global__ void bestTwoCycle(int n, twoCycleTrial *data, float *area,int m){
    int index = threadIdx.x+blockIdx.x*blockDim.x;
    int stride=blockDim.x*gridDim.x;
    for(int k=index;k<n;k+=stride){
        float x1=data[k].c1X;
        float y1=data[k].c1Y;
        float x2=data[k].c2X;
        float y2=data[k].c2Y;
        float r1=data[k].h1*data[k].d;
        float r2=data[k].h2*data[k].d;
        float r3=r1-data[k].d;
        float rr3=r3*r3;
        float rr1=r1*r1;
        float rr2=r2*r2;
        float total=0.0;
        for(int l=0;l<m;){
            float i=area[l++];
            float j=area[l++];
            float di1=x1-i;
            float dj1=y1-j;
            float di2=x2-i;
            float dj2=y2-j;
            if (di1*di1+dj1*dj1<=rr1 && di1*di1+dj1*dj1>rr3 && di2*di2+dj2*dj2<=rr2)
                total+=1.0;
        }
        float rate=total / (data[k].tArea+0.1);
        float rate3=rate*rate*rate;
        if (rate3<1.1){
                
            data[k].grAr=rate3*total ; 
            data[k].acAr=total;
            data[k].rate3=rate3;
        }
    }    

}

__global__ void goOver1(int n, twoCycleTrial *data, float *area,int m){
    int index = threadIdx.x+blockIdx.x*blockDim.x;
    int stride=blockDim.x*gridDim.x;
    for(int k=index;k<n;k+=stride){
        float x1=data[k].c1X;
        float y1=data[k].c1Y;
        float x2=data[k].c2X;
        float y2=data[k].c2Y;
        float r1=data[k].h1*data[k].d;
        float r2=data[k].h2*data[k].d;
        float r3=r1-data[k].d;
        float rr3=r3*r3;
        float rr1=r1*r1;
        float rr2=r2*r2;
        float total=0.0;
        for(int l=0;l<m;){
            float i=area[l++];
            float j=area[l++];
            float di1=x1-i;
            float dj1=y1-j;
            float di2=x2-i;
            float dj2=y2-j;
            if (di1*di1+dj1*dj1<=rr1 && di1*di1+dj1*dj1>rr3 && di2*di2+dj2*dj2<=rr2)
                total+=1.0;
        }

        float rate3=data[k].rate3;

        data[k].grAr=rate3*total ; 
        data[k].acAr=total;

    }    

}

void User:: genTAS(int ts)
{
    TAS.clear();
    totalStroke=ts;
    int width=1;
    for( int i=0;i<ts;i++)
    {
        if(tx[i]<0)
        {
            width=ty[i];
        
        }
        else
        {
            if(tx[i-1]>0)
            {
                Point preP={tx[i-1],ty[i-1]};
                Point curP={tx[i],ty[i]};
                addToTAS(preP,curP,width);
            
            }
            else
            {
                Point curP={tx[i],ty[i]};
                addToTAS(curP,width);
            
            }
        
        }
    
    }

}

void User:: addToTAS(Point p, int width)
{
    int lx= p.m_X-width / 2 < 0? 0 : p.m_X-width / 2;
    int ly= p.m_Y-width / 2 < 0? 0 : p.m_Y-width / 2;
    for( int i=lx; i<p.m_X+width / 2;i++)
    {
        for(int j=ly;j<p.m_Y+width / 2;j++)
        {
            Point curP={i,j};
            if(pDis(curP, p)<width*width / 4)TAS.insert(to_string(curP.m_X)+" "+to_string(curP.m_Y));
        }
    }


}


void User:: addToTAS(Point p1, Point p2,int width)
{
    int lx1= p1.m_X-width / 2<0?0:p1.m_X-width / 2;
    int ly1= p1.m_Y-width / 2<0?0:p1.m_Y-width / 2;
    int lx2= p2.m_X-width / 2<0?0:p2.m_X-width / 2;
    int ly2= p2.m_Y-width / 2<0?0:p2.m_Y-width / 2;
    int rx= p1.m_X+width / 2<p2.m_X+width / 2?p2.m_X+width / 2:p1.m_X+width / 2;
    int ry= p1.m_Y+width / 2<p2.m_Y+width / 2?p2.m_Y+width / 2:p1.m_Y+width / 2;
    int lx=lx1<lx2?lx1:lx2;
    int ly=ly1<ly2?ly1:ly2;
    
    for( int i=lx; i<rx;i++)
    {
        for(int j=ly;j<ry;j++)
        {
            Point curP={i,j};
            if(lDis(curP, p1,p2)<width*width / 4)TAS.insert(to_string(curP.m_X)+" "+to_string(curP.m_Y));
        }
    }
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

float rootX(float y,float a,float b)
{
  return sqrt(b*b+y*y)*a/b; 
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

float testInterHyperCycle()
{
   while(1)
   {
     
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
     cout<<"type in data: ";
     cin>>h1.m_X;
     cin>>h1.m_Y;   
     cin>>h2.m_X;
     cin>>h2.m_Y;
     cin>>c1.m_X; 
     cin>>c1.m_Y;
     cin>>ah;
     cin>>h3;
     cin>>avgHopDis1;
     cin>>avgHopDis2;     
     cin>>suppose; 
     vector<float> f1;
     vector<float> f2;
     float cal=findInterHyperCycle( h1, h2, c1, ah, h3, avgHopDis1, avgHopDis2, f1);
     float cal2=findInterHyperCycle( h1, h2, c1, ah-1, h3, avgHopDis1, avgHopDis2, f2);
     
     cout<<"cal: "<<cal<<endl;
     cout<<"cal2: "<<cal2<<endl;
     cout<< "calculated value: "<<cal-cal2<<" VS "<<"real Value: "<<suppose<<endl;
     
                           
   }
}

float findInterEllipseCycle(Point h1,Point h2,Point c1,int ah,int h3,float avgHopDis1,float avgHopDis2,vector<float>& yr )
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
    yr.push_back(-12345);
    yr.push_back(c2x);
    return 0;
  }
  
  vector<tuple<float,float>> rrr = getRoot(c2x, c2y, r, a, b,yr);
  
  
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

int euDis(int x1, int y1, int x2, int y2)
{
    return (x1-x2)*(x1-x2)+(y1-y2)*(y1-y2);
}

int pDis(Point p1, Point p2)
{
    return (p1.m_X-p2.m_X)*(p1.m_X-p2.m_X)+(p1.m_Y-p2.m_Y)*(p1.m_Y-p2.m_Y);
}

int lDis(Point p0, Point p1, Point p2)
{
    if(p2.m_X!=p1.m_X && p2.m_Y != p1.m_Y)
        return ((p2.m_X-p1.m_X)*(p1.m_Y-p0.m_Y)-(p1.m_X-p0.m_X)*(p2.m_Y-p1.m_Y))*((p2.m_X-p1.m_X)*(p1.m_Y-p0.m_Y)-(p1.m_X-p0.m_X)*(p2.m_Y-p1.m_Y))/((p2.m_X-p1.m_X)*(p2.m_X-p1.m_X)+(p2.m_Y-p1.m_Y)*(p2.m_Y-p1.m_Y));
    else
        return sqrt(pDis(p0,p1));
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



int getUser(string tmpID){
    
    if(indexMap.find(tmpID)==indexMap.end()){
        
        User curUser=User(tmpID);
        userNow=(userNow+1)%userSize;
        cout<<"Setting up a new User :"<<tmpID<<" at: "<<userNow<<endl;
        if(idList[userNow].length()>0)indexMap.erase(idList[userNow]);
        idList[userNow]=tmpID;
        indexMap.insert(make_pair(tmpID,userNow));
        allUser[userNow]=curUser;
        return userNow;
    }
    else{
        return  indexMap[tmpID];
    
    }
}

void setupUser(string tmpID,int epoch,int nodeNum,int anchorNum,int radioRange)
{
    User& curUser = allUser[getUser(tmpID)];
    //cout<<epoch<<" : "<<curUser.getEpoch()<<endl;
    if(epoch >= curUser.getEpoch())
    {
        curUser.setNodes(nodeNum);
        curUser.setAnchor(anchorNum);
        curUser.setEpoch(epoch);
        curUser.setRange(radioRange);
        cout<<"setting up user: "<<  tmpID <<" in: "<<getUser(tmpID)<<endl;
    }
}

void addTrajectory(string tmpID,int epoch,int traInd, int X,int Y)
{
    User& curUser = allUser[getUser(tmpID)];
    //cout<<epoch<<" : "<<curUser.getEpoch()<<endl;
    if(epoch >= curUser.getEpoch())
    {
        curUser.setEpoch(epoch);
        curUser.setTraj(X,Y,traInd);
        
    }
}


void setupTAS(string tmpID,int epoch, string requestID, int totalStroke)
{
    //cout<<"setting TAS"<<endl;
    User& curUser = allUser[getUser(tmpID)];
    //cout<<epoch<<" : "<<curUser.getEpoch()<<endl;
    if(epoch >= curUser.getEpoch() && curUser.resultMap.find(requestID)==curUser.resultMap.end())
    {
      //cout<<"push to computing Queue for : " <<tmpID+" "+requestID<<endl;
      curUser.resultMap.insert(make_pair(requestID,""));
      curUser.genTAS(totalStroke);
      computingQueue.push(tmpID+" "+requestID);
      //cout<<"push to computing Queue for : " <<tmpID+" "+requestID<<endl;
      //curUser.printArea();
      
    }
    else
    {
      cout<<"The computation requestion already in processing"<<endl;
    
    }
}


void configNodes(string tmpID,int epoch,int nodeID,int X,int Y)
{
    User& curUser = allUser[getUser(tmpID)];
    if(epoch >= curUser.getEpoch())
    {
        curUser.setX(nodeID,X);
        curUser.setY(nodeID,Y);
    }   


}


int myStoi(string data)
{
     stringstream geek(data); 
    
    // The object has the value 12345 and stream 
    // it to the integer x 
    int x = 0; 
    geek >> x;
    //cout<<"transfer string "<<data<<"to integer "<<x<<endl; 
    return x;

}

string getRoutingMSG(string userRequest)
{
    string res="";
    stringstream ur(userRequest);
    string tmpID;
    string requestID;
    ur>>tmpID;
    ur>>requestID;
    User& curUser = allUser[getUser(tmpID)];
    
    float *TAS,*d_TAS;
    int tasSize=curUser.TAS.size();
    TAS=(float*)malloc(sizeof(float)*tasSize*2);
    cudaMalloc((void**)&d_TAS, sizeof(float) *tasSize*2);
    int counter=0;
    for(string t:curUser.TAS)
    {
        stringstream tt(t);
        float x,y;
        tt>>x;
        tt>>y;
        TAS[counter++]=x;
        TAS[counter++]=y;
    }
    cudaMemcpy(d_TAS, TAS, sizeof(float) *tasSize*2, cudaMemcpyHostToDevice);
    
    //cout<<"I'm OK Here"<<endl;
    short hv[nodeSize][anchorSize];
    curUser.getHopInfo(hv);
    vector<twoCycleTrial> cycleTrials=curUser.findTwoCycleTrial(hv);
    counter=0; 
    twoCycleTrial *cTri;
    twoCycleTrial *d_cTri;
    if(!cycleTrials.empty())
    {
        cTri=(twoCycleTrial*)malloc(sizeof(twoCycleTrial)*cycleTrials.size());
        
        //cout<<"I'm OK after here"<<endl;
        for(twoCycleTrial ct: cycleTrials)
        {
            cTri[counter++]=ct;
        }
        cudaMalloc((void**)&d_cTri, sizeof(twoCycleTrial) *cycleTrials.size());
        cudaMemcpy(d_cTri,cTri,sizeof(twoCycleTrial) *cycleTrials.size(),cudaMemcpyHostToDevice);
        cout<<"finish copy totoal trial: "<<cycleTrials.size()<<endl;        
        bestTwoCycle<<<2048,256>>>(cycleTrials.size(),d_cTri,d_TAS,tasSize*2);
       
        //cudaFree(d_cTri);
    }
    vector<hyperTrial> hyperTrials=curUser.findHyperTrial(hv);   
    //cout<<"number of hyperTrial: "<<hyperTrials.size()<<endl;
    hyperTrial *hTri;
    hyperTrial *d_hTri;
    int counter2=0;
    if(!hyperTrials.empty())
    {
        hTri=(hyperTrial*)malloc(sizeof(hyperTrial)*hyperTrials.size());

        //cout<<"I'm OK after here"<<endl;
        for(hyperTrial ht: hyperTrials)
        {
            hTri[counter2++]=ht;
        }
        cudaMalloc((void**)&d_hTri, sizeof(hyperTrial) *hyperTrials.size());        
        cudaMemcpy(d_hTri,hTri,sizeof(hyperTrial) *hyperTrials.size(),cudaMemcpyHostToDevice);
        cout<<"finish copy totoal trial: "<<hyperTrials.size()<<endl;
        cout<<"********TAS size is: "<<tasSize<<"******"<<endl;
        bestHyper<<<2048,256>>>(hyperTrials.size(),d_hTri,d_TAS,tasSize*2);
        //cudaDeviceSynchronize();
        
        //cudaFree(d_hTri);
    }
    
    if(cycleTrials.empty() || hyperTrials.empty())return "No result";
    cudaDeviceSynchronize();
    cudaMemcpy(cTri,d_cTri,sizeof(twoCycleTrial) *cycleTrials.size(),cudaMemcpyDeviceToHost); 
    cudaMemcpy(hTri,d_hTri,sizeof(hyperTrial) *hyperTrials.size(),cudaMemcpyDeviceToHost);  
      
    cout<<counter<<" ||||||| "<<counter2<<" ||||||||||  "<<tasSize<<endl;
    res+=findBestTry(cTri,hTri, counter, counter2, curUser.TAS);
    
    sort(cTri, cTri+counter, sortCycleTrial);
    sort(hTri, hTri+counter2, sortHyperTrial);
    counter = 1000000 < counter ? 1000000 : counter;
    counter2 = 5000000 < counter2 ? 5000000 : counter2;
    
    
    //cudaMalloc((void**)&d_cTri, sizeof(twoCycleTrial) *counter);
    cudaMemcpy(d_cTri,cTri,sizeof(twoCycleTrial) *counter, cudaMemcpyHostToDevice);
    //cudaMalloc((void**)&d_hTri, sizeof(hyperTrial) *counter2);  
    cudaMemcpy(d_hTri,hTri,sizeof(hyperTrial) *counter2, cudaMemcpyHostToDevice);

    int newSize = 0;
    do
    {
      
      newSize=curUser.TAS.size();
      cout<<counter<<" ||||||| "<<counter2<<" ||||||||||  "<<newSize<<endl;
      int tasInd=0;
      for(string t:curUser.TAS)
      {
          stringstream tt(t);
          float x,y;
          tt>>x;
          tt>>y;
          TAS[tasInd++]=x;
          TAS[tasInd++]=y;
      }
      //cudaFree(d_TAS);
      //cudaMalloc((void**)&d_TAS, sizeof(float) *newSize*2);
      cudaMemcpy(d_TAS, TAS, sizeof(float) *newSize*2, cudaMemcpyHostToDevice);
      goOver1<<<2048,256>>>(counter, d_cTri, d_TAS, newSize*2);
      goOver2<<<2048,256>>>(counter2, d_hTri, d_TAS, newSize*2);
      cudaDeviceSynchronize();
      
      //free(cTri);
      //free(hTri);
      //cTri=(twoCycleTrial*)malloc(sizeof(twoCycleTrial)*counter);
      //hTri=(hyperTrial*)malloc(sizeof(hyperTrial)*counter2);
      cudaMemcpy(cTri,d_cTri,sizeof(twoCycleTrial) *counter,cudaMemcpyDeviceToHost);  
      cudaMemcpy(hTri,d_hTri,sizeof(hyperTrial) *counter2,cudaMemcpyDeviceToHost);
      res+=findBestTry(cTri,hTri, counter, counter2, curUser.TAS);
    }while(newSize>0.15*tasSize);
    
    cudaFree(d_cTri);
    cudaFree(d_hTri);
    cudaFree(d_TAS);
    free(TAS);
    free(cTri); 
    free(hTri);     
    return res;

}








void addData(string data)
{
    int begin=data.find("*,");
    int end=data.find(",*",begin+1);
    //cout<<data<<endl;
    if(begin>=0&&end>begin)
    {
        string realData=data.substr(begin+2,end-begin-2);

        int length=realData.length();
        int comma=0;
        for(int i=0;i<length;i++){
            if(realData[i]==',')comma++;
        }
        //cout<<realData<<endl;
        if(comma==5){
            int first=realData.find(",");
            string tmpID=realData.substr(0,first);
            //cout<<tmpID.length()<<endl;
            if(tmpID.length()!=8 || tmpID.find("0.") == string::npos )return;
            
            int second=realData.find(",",first+1);
            int third=realData.find(",",second+1);
            int fourth=realData.find(",",third+1);
            int fifth=realData.find(",",fourth+1);
            
            int epoch=myStoi(realData.substr(first+1,second-first));
            int mod=myStoi(realData.substr(second+1,third-second));
            //cout<<mod<<endl;
            if(mod==0){
            
                int nodeNum=myStoi(realData.substr(third+1,fourth-third));
                int anchorNum=myStoi(realData.substr(fourth+1,fifth-fourth));
                int radioRange=myStoi(realData.substr(fifth+1,length-fourth));
                //cout<<"0: "<<tmpID<<":"<<epoch<<endl;
              if(nodeNum<nodeSize&&anchorNum<anchorSize&&radioRange<=200&&nodeNum>0&&anchorNum>0&&radioRange>0)
                setupUser(tmpID,epoch,nodeNum,anchorNum,radioRange);
            }
            if(mod==1){
                int nodeID=myStoi(realData.substr(third+1,fourth-third));
                int X=myStoi(realData.substr(fourth+1,fifth-fourth));
                int Y=myStoi(realData.substr(fifth+1,length-fourth));
              if(nodeID<nodeSize&&nodeID>=0)  
                configNodes(tmpID,epoch,nodeID,X,Y);
            }
            if(mod==3){
                int traInd=myStoi(realData.substr(third+1,fourth-third));
                int X=myStoi(realData.substr(fourth+1,fifth-fourth));
                int Y=myStoi(realData.substr(fifth+1,length-fourth));
              if(traInd<strokeSize&&traInd>=0)
                addTrajectory(tmpID,epoch,traInd,X,Y);
            }
            if(mod==4){
                //cout<<"third: "<<third<<"fourth: "<<fourth<<endl;
                string requestID=realData.substr(third+1,fourth-third-1);
                int totalStroke=myStoi(realData.substr(fourth+1,fifth-fourth));
                if(totalStroke<strokeSize)
                {
                    cout<<"request realDATA "<<realData<<endl;
                    cout<<"here is the requestID "<<requestID<<endl;
                    setupTAS(tmpID,epoch,requestID, totalStroke);
                }
            
            }
            
            

        }

    }
    else
    {
        //cout<<"here is nonesense: "<<data<<endl;
    
    
    }

}

/**
	Connect to a host on a certain port number
*/
bool tcp_client::conn(string address , int port)
{
	//create socket if it is not already created
	if(sock == -1)
	{
		//Create socket
		sock = socket(AF_INET , SOCK_STREAM , 0);
		if (sock == -1)
		{
			perror("Could not create socket");
		}
		
		cout<<"Socket created\n";
	}
	else	{	/* OK , nothing */	}
	
	//setup address structure
	if(inet_addr(address.c_str()) == -1)
	{
		struct hostent *he;
		struct in_addr **addr_list;
		
		//resolve the hostname, its not an ip address
		if ( (he = gethostbyname( address.c_str() ) ) == NULL)
		{
			//gethostbyname failed
			herror("gethostbyname");
			cout<<"Failed to resolve hostname\n";
			
			return false;
		}
		
		//Cast the h_addr_list to in_addr , since h_addr_list also has the ip address in long format only
		addr_list = (struct in_addr **) he->h_addr_list;

		for(int i = 0; addr_list[i] != NULL; i++)
		{
			//strcpy(ip , inet_ntoa(*addr_list[i]) );
			server.sin_addr = *addr_list[i];
			
			cout<<address<<" resolved to "<<inet_ntoa(*addr_list[i])<<endl;
			
			break;
		}
	}
	
	//plain ip address
	else
	{
		server.sin_addr.s_addr = inet_addr( address.c_str() );
	}
	
	server.sin_family = AF_INET;
	server.sin_port = htons( port );
	
	//Connect to remote server
	if (connect(sock , (struct sockaddr *)&server , sizeof(server)) < 0)
	{
		perror("connect failed. Error");
		return 1;
	}
	
	cout<<"Connected\n";
	return true;
}

/**
	Send data to the connected host
*/
bool tcp_client::send_data(string data)
{
	//Send some data
	if( send(sock , data.c_str() , strlen( data.c_str() ) , 0) < 0)
	{
		perror("Send failed : ");
		return false;
	}
	
	return true;
}

/**
	Receive data from the connected host
*/
void tcp_client::receive(char buffer[])
{
	
	buffer[0]=' ';


	
	//Receive a reply from the server
	if( recv(sock , buffer , 1024 , 0) < 0)
	{
		puts("recv failed");
	
    }
    string to;
    stringstream ss(buffer);
    if(buffer!=NULL)
    {
        while(getline(ss,to,'\n')){
            stringQueue.push(to);
        }
	}

    
	receive(buffer);
}


void handle(tcp_client c)
{
    
   c.send_data("abc");

}


void repeatSend(tcp_client c)
{

    unsigned long  counter=0;
    while(1)
    {
        
        c.send_data(to_string(counter++));
        this_thread::sleep_for(chrono::milliseconds(5000));   
    }

}


void listenString()
{
    
    while(1)
    {
        
        
        if(!stringQueue.isEmpty())
        {
            
            string popString=stringQueue.pop();
            addData(popString);
            
        }
        this_thread::sleep_for(chrono::microseconds(100));   
    }
}


void computationQueueHandle(tcp_client c)
{
  while(1)
  {
    if(!computingQueue.isEmpty())
    {
        
        string popString=computingQueue.pop();
        if(popString.size()> 10){
            cout<<"computing "<<popString<<endl;
            string res=getRoutingMSG(popString); 
            cout<<"======Result: "<<res<<endl;
            c.send_data(popString+res); 
            c.send_data(popString+res);           
        }

        
    }
    this_thread::sleep_for(chrono::microseconds(100));   
  }
}

void add(int id)
{
    int count=-2000000000;
    while(count<2000000000)count=count+1;
    intQueue.push(id);
    return;

}

int main(int argc , char *argv[])
{  
  srand(time(NULL));
///*
	tcp_client c;
	string host="64.251.147.176";

  
	
	//connect to host
	c.conn(host , 7676);
    thread stringListeningThread(listenString);	
    thread hh(repeatSend,c);
    thread cq(computationQueueHandle,c);
	//receive and echo reply
	char buffer[4096];
	c.receive(buffer);
//*/
	//done
	//testInterHyperCycle();
	return 0;
}
 
 
 