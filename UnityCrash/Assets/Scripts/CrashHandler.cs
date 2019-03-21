using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Text;
using UnityEngine;
using System.Runtime.InteropServices;

public class CrashHandler : MonoBehaviour
{
  UnityCrashFinder unityCrashFinder;
  private void Start()
  {
    unityCrashFinder = UnityCrashFinder.GetInstance();
    unityCrashFinder.startEngine();
    for (int i = 0; i < 3; i++)
    {
      Debug.Log("aaa");
    }
  }

  public void clickCrash()
  {
    Debug.LogError("clickCrash");
    int[] str = new int[2] { 1, 2 };
    for (int i = 0; i < 3; i++)
    {
      Debug.Log(str[i]);
    }
  }
  void Update()
  {
    unityCrashFinder.UpdateLog();
  }

  public string GetMethodInfo()
  {
    string str = "";

    //取得当前方法命名空间    
    str += "命名空间名:" + System.Reflection.MethodBase.GetCurrentMethod().DeclaringType.Namespace + "\n";

    //取得当前方法类全名 包括命名空间    
    str += "类名:" + System.Reflection.MethodBase.GetCurrentMethod().DeclaringType.FullName + "\n";

    //取得当前方法名    
    str += "方法名:" + System.Reflection.MethodBase.GetCurrentMethod().Name + "\n"; str += "\n";

    //父方法
    System.Diagnostics.StackTrace ss = new System.Diagnostics.StackTrace(true);
    System.Reflection.MethodBase mb = ss.GetFrame(1).GetMethod();

    //取得父方法命名空间    
    str += mb.DeclaringType.Namespace + "\n";

    //取得父方法类名    
    str += mb.DeclaringType.Name + "\n";

    //取得父方法类全名    
    str += mb.DeclaringType.FullName + "\n";

    //取得父方法名    
    str += mb.Name + "\n"; return str;
  }
}
