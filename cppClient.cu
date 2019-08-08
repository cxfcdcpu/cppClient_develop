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
#include "allConstant.h"
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
#include "Point.h"
#include "CycleTrial.h"
#include "HyperTrial.h"
#include "generalFunction.h"
#include "userClass.h"



using namespace std;

/**
	TCP Client class
*/



class tcp_client
{
private:
	int sock;
	std::string address;
	int port;
	struct sockaddr_in server;
	
public:
	tcp_client();
  Queue<string> stringQueue;
  Queue<string> computingQueue;
	bool conn(string, int);
	void listenString();
	void repeatSend();
	void computationQueueHandle();
	bool send_data(string data);
	void addData(string data);
  void setupTAS(string tmpID,int epoch, string requestID,int totalStroke);
	void receive(char buf[]);
};



map<string,int> indexMap;

User allUser[userSize];
string idList[userSize];

int userNow=-1;




int getUser(string tmpID);
void setupUser(string tmpID,int epoch,int nodeNum,int anchorNum,int radioRange);
void configNodes(string tmpID,int epoch,int nodeID,int X,int Y);
void addTrajectory(string tmpID,int epoch,int traInd,int X,int Y);



tcp_client::tcp_client()
{
	sock = -1;
	port = 0;
	address = "";
}



/*
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
*/


/*
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
*/




__global__ void goOver3(int n, ellipseTrial *data, float *area,int m){
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
            float tt = sqrtf((i-h1x)*(i-h1x)+(j-h1y)*(j-h1y))+sqrtf((i-h2x)*(i-h2x)+(j-h2y)*(j-h2y));
            float di = x-i;
            float dj = y-j;
            if(di * di + dj * dj <= rr && tt <= 2*a && tt >= 2* a2) total+=1.0;
        }

        float rate3 = data[k].rate3;
        data[k].grAr=rate3*total;
        data[k].acAr = total;

    }
}

__global__ void bestEllipse(int n, ellipseTrial *data, float *area,int m){
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
            float tt = sqrtf((i-h1x)*(i-h1x)+(j-h1y)*(j-h1y))+sqrtf((i-h2x)*(i-h2x)+(j-h2y)*(j-h2y));
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









/*
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

*/


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


void tcp_client::setupTAS(string tmpID,int epoch, string requestID, int totalStroke)
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


void tcp_client::addData(string data)
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



void tcp_client::repeatSend()
{

    unsigned long  counter=0;
    while(1)
    {
        
        send_data(to_string(counter++));
        this_thread::sleep_for(chrono::milliseconds(5000));   
    }

}


void tcp_client::listenString()
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


void tcp_client::computationQueueHandle()
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
            send_data(popString+res); 
            send_data(popString+res);           
        }

        
    }
    this_thread::sleep_for(chrono::microseconds(100));   
  }
}



int main(int argc , char *argv[])
{  
  srand(time(NULL));
///*
	tcp_client  c ;
	string host="64.251.147.176";  
	
	//connect to host
	c.conn(host , 6267);
  thread stringListeningThread(&tcp_client::listenString, &c);	
  thread hh(&tcp_client::repeatSend,&c);
  thread cq(&tcp_client::computationQueueHandle,&c);
	//receive and echo reply
	char buffer[4096];
	c.receive(buffer);
//*/

	return 0;
}
 
 
 
