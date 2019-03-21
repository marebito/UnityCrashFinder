//
//  UnityCrashFinder.cs
//  UnityCrashFinder
//
//  Created by Yuri Boyka on 2019/3/20.
//  Copyright © 2019 Yuri Boyka. All rights reserved.
//

using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Text;
using UnityEngine;
using System.Runtime.InteropServices;

public class UnityCrashFinder : MonoBehaviour
{
#if UNITY_IOS || UNITY_STANDALONE

  private static UnityCrashFinder uniqueInstance;

  public static UnityCrashFinder GetInstance()
  {
    if (uniqueInstance == null)
    {
      uniqueInstance = new UnityCrashFinder();
    }
    return uniqueInstance;
  }

  List<string> mWriteTxt = new List<string>();
  public void startEngine()
  {
    Application.logMessageReceived += HandleLog;
#if UNITY_STANDALONE
    if (File.Exists(Application.dataPath + "/Log/log.txt"))
    {
      File.Delete(Application.dataPath + "/Log/log.txt");
    }
#endif
  }
  
  public void stopEngine()
  {
    Application.logMessageReceived -= HandleLog;
  }

#if UNITY_IOS
  [DllImport("__Internal")]
  private static extern int __CSharpWriteLog(string logMessage, string stackTrace, int type);
#endif

  void HandleLog(string logString, string stackTrace, LogType type)
  {
#if UNITY_STANDALONE
    mWriteTxt.Add(logString);
#endif
#if UNITY_IOS
    __CSharpWriteLog(logString, stackTrace, (int)type);
#endif
  }

  public void UpdateLog()
  {
    if (mWriteTxt.Count > 0)
    {
      string[] temp = mWriteTxt.ToArray();
      foreach (string t in temp)
      {
#if UNITY_STANDALONE
        using (StreamWriter writer = new StreamWriter(Application.dataPath + "/Log/log.txt", true, Encoding.UTF8))
        {
          writer.WriteLine(t);
        }
#endif
        mWriteTxt.Remove(t);
      }
    }
  }
#endif
}
