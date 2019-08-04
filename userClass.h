#include <iostream>


using namespace std;

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
        for(int i=0;i<5000;i++)
        {
          tx[i]=-1;
          ty[i]=-1;
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
        for(int i=0;i<5000;i++)
        {
          tx[i]=-1;
          ty[i]=-1;
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



