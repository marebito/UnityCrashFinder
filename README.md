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

如果是PC/Linux/Mac平台，则需要在Asset目录下手动创建一个Log文件夹
