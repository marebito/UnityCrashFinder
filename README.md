#  Unity-iPhone崩溃查找工具
---

## 导入步骤:
1. 将静态库libUnityCrashFinder.a及include文件夹拖入Unity工程中的Asset/Plugins/iOS目录下
2. 在你的启动场景绑定的C#脚本中作如下改动：
```
UnityCrashFinder unityCrashFinder;

void Start()
{
    unityCrashFinder = UnityCrashFinder.GetInstance();
    unityCrashFinder.startEngine();
}

void Update()
{
    unityCrashFinder.UpdateLog();
}
```

3. 如果需要在在手机上查看崩溃日志，需要开启BackgroundMode
    * Xcode选中目标Target --> Capabilities --> Background (ON)
4. 在导出的项目中引入libz.tbd和MobileCoreServices.framework
5. 集成完成
6. 运行导出的Unity-iPhone项目

如果是PC/Linux/Mac平台，则需要在Assets目录下手动创建一个Log文件夹

> 样例工程UnityCrash使用(需要Unity2018.3.0f及以上版本)

从样例工程中导出iOS工程，直接运行，点击"Force Crash"按钮即可看到崩溃提示，如果未开启BackgroundMode，则需要在Mac上的浏览器中打开提示弹窗中的地址以查看崩溃堆栈，如果开启了BackgroundMode，点击"查看日志"按钮，则自动跳转到手机中的Safari浏览器并加载异常崩溃日志，查看日志堆栈信息并定位崩溃代码
