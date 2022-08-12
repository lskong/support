# ceph开发流程架构文档[基于v15.2.10]

- [ceph开发流程架构文档[基于v15.2.10]](#ceph开发流程架构文档基于v15210)
    - [mgr组件](#mgr组件)
        - [MgrStandby](#mgrstandby)
        - [Mgr](#mgr)
        - [DaemonServer](#daemonserver)
        - [PyModules](#pymodules)
        - [ClusterState](#clusterstate)
        - [DaemonState](#daemonstate)
    - [ceph-mgr 类图](#ceph-mgr-类图)
    - [Ceph-Mgr 启动过程](#ceph-mgr-启动过程)
    - [Python plugin开发](#python-plugin开发)
        - [编写自定义plugin](#编写自定义plugin)
            - [参考hello模块, 在插件目录下新增一个模块文件夹, 然后按照hello模块的格式进行编写](#参考hello模块-在插件目录下新增一个模块文件夹-然后按照hello模块的格式进行编写)
            - [步骤二：配置ceph.conf文件，让ceph-mgr启动时加载hello这个plugin，修改如下：](#步骤二配置cephconf文件让ceph-mgr启动时加载hello这个plugin修改如下)
        - [cli开启与调用plugin](#cli开启与调用plugin)
        - [dashboard和restful模块](#dashboard和restful模块)
            - [ceph_module](#ceph_module)
            - [ceph_logger](#ceph_logger)
        - [pybind实现C++的接口](#pybind实现c的接口)
            - [PyModule.cc](#pymodulecc)
            - [自定义pybind接口模块](#自定义pybind接口模块)
    - [Mgr初始化流程及线程模型](#mgr初始化流程及线程模型)
        - [Initialize Messenger](#initialize-messenger)
        - [Initialize MonClient](#initialize-monclient)
        - [Initialize MgrClient](#initialize-mgrclient)
        - [Initialize python plugin](#initialize-python-plugin)


## mgr组件
ceph-mgr的重要类或模块包括：MgrStandy、Mgr、DaemonServer、PyModules、ClusterState、DaemonState等.其主要功能描述如下：

### MgrStandby
所有mgr服务启动时身份都是standby, 唯一作用是包含一个mgr的client端, 获取mgrmap及相关msg.在获取了mgr-map发现自己为当前active时, 才会初始化mgr主服务进程.当mgrmap中变为非active状态, 则shutdown mgr主服务进程, 释放资源.


### Mgr
主要工作是初始化daemonserver、pymodules、clusterstate等主要功能类, 并handle standby mgr client的非mgrmap的消息（osdmap、pgmap、fsmap等）.执行了monc->sub_want()函数, 注册了定期获取数据操作.

### DaemonServer
为mgr主要的服务进程, 和osd、mds等类似, 初始化了一个mgr类型的Messenger, 监听有关mgr消息, 主要是MSG_PGSTATS、MSG_MGR_REPORT、MSG_MGR_OPEN、MSG_COMMAND.比如执行‘ceph tell mgr {command}’时就被发送到daemonserver中handle_command函数进行处理（包括了native命令和plugin的commands）

### PyModules
包含ActivePyModule、StandbyPyModules、ActivePyModules、BaseMgrModules、BaseMgrStandbyModules、PyModulesRegistry、PyModuleRunner等类, 分别处理mgr处于active和standby时对plugins的处理, 并在active时初始化python的运行环境, 将plugin模块初始化并加载运行.该类大量使用了python的c++扩展接口.

### ClusterState

保存了cluster的状态, 部分状态在monc中, 由mgr类定期更新状态（ms_dispatch）

### DaemonState
保存了DaemonServer的状态信息
这些类之间的关系如下图所示：


## ceph-mgr 类图

![ceph-mgr 类图](/img/ceph-mgr-class.jpg "Magic Gardens")


## Ceph-Mgr 启动过程

![Ceph-Mgr 启动过程](/img/Ceph-Mgr-boost-proccess.jpg "Magic Gardens")


**注意：图中的ceph-mgr.cc在v15.2.10里的文件名叫做ceph_mgr.cc**


## Python plugin开发

mgr提供了常用的几种函数接口，只要重载这些接口，就能开发plugin实现特定功能。以下是官方的介绍，即实现服务器、消息通知、自定义命令等功能：

    serve: member function for server-type modules. This function should block forever.

    notify: member function if your module needs to take action when new cluster data is available.

    handle_command: member function if your module exposes CLI commands.

### 编写自定义plugin

#### 参考hello模块, 在插件目录下新增一个模块文件夹, 然后按照hello模块的格式进行编写

步骤一：在src/pybind/mgr/ 目录下新建一个plugin，名字为hello， 然后在hello目录下新建一个名为 init.py 和 module.py（名字必须是 module.py，这是mgr程序识别这个plugin的核心文件）。两个文件内容如下所示：

    # __init__.py
    from module import *  # NOQA

========================================================

    # module.py
    from mgr_module import MgrModule

    class Module(MgrModule):
    COMMANDS = [
        {
            "cmd": "hello",
            "desc": "Say Hello",
            "perm": "r"
        }
    ]

    def handle_hello(self, cmd):
        return 0, "", "Hello World"

    def handle_command(self, cmd):
        self.log.error("handle_command")

        if cmd['prefix'] == "hello":
            return self.handle_hello(cmd)
        else:
            raise NotImplementedError(cmd['prefix'])

#### 步骤二：配置ceph.conf文件，让ceph-mgr启动时加载hello这个plugin，修改如下：
    [mgr]
        mgr modules = restful dashboard hello
        mgr data = /home/hhd/github/ceph/build/dev/mgr.\$id
        mgr module path = /home/hhd/github/ceph/src/pybind/mgr
        

### cli开启与调用plugin
使用ceph mgr module enable \$module_nameh或 init-ceph restart mgr启用模块后, 就可以直接ceph \$module_name进行使用

### dashboard和restful模块
在mgr中, dashboard和restful的一些初始化和控制接口, 服务端口, web前后端都是以plugin形式加载的, 它们各自web服务端口都是在自身的CherryPy框架里设置并启动web服务, src/pybind/dashboard目录下后端代码和REST API使用CherryPy框架实现.WebUI基于Angular 实现, 放在src/pybind/dashboard/frontend下, 二次定制dashboard, restful基本上只需要修改对应的module下的文件

#### ceph_module
这个python模块包含BaseMgrModule, BaseMgrStandbyModule, BasePyOSDMap, BasePyOSDMapIncremental, BasePyCRUSH等C++导出类

#### ceph_logger
这个python模块为C++实现的C++日志类导出

### pybind实现C++的接口

#### PyModule.cc
此文件为所有pybind加载的总入口， 在init_ceph_module(), init_ceph_logger()两个函数中进行C++模块的加载， 两个函数内容如下所示：

    void PyModule::init_ceph_logger() {
      
       py_logger = ("ceph_logger", log_methods);
      PySys_SetObject(const_cast<char*>("stderr"), py_logger);
      PySys_SetObject(const_cast<char*>("stdout"), py_logger);
    }

    void PyModule::init_ceph_module() {
      ...
      PyObject *ceph_module = Py_InitModule("ceph_module", module_methods);

      std::map<const char*, PyTypeObject*> classes{
        {{"BaseMgrModule", &BaseMgrModuleType},
        {"BaseMgrStandbyModule", &BaseMgrStandbyModuleType},
        {"BasePyOSDMap", &BasePyOSDMapType},
        {"BasePyOSDMapIncremental", &BasePyOSDMapIncrementalType},
        {"BasePyCRUSH", &BasePyCRUSHType}}
      };
    }

BaseMgrModule， BaseMgrStandbyModule， BasePyOSDMap，BasePyOSDMapIncremental，BasePyCRUSH即为其当前加载的pybind模块

#### 自定义pybind接口模块
主要有 BaseMgrModule.cc， BaseMgrStandbyModule.cc， BasePyOSDMap.cc，BasePyOSDMapIncremental.cc，BasePyCRUSH.cc 等文件，作用是生成pybind导出类的各种接口, 它们只是作为一个代理, 只在接口实现pybind规范以进行参数传输与调用真正实现C++方法的， 需要定制或者新增接口的话, 在对应的C++模块中进行扩展, 举个例子， BaseMgrModule.cc模块重点内容如下所示：

**真正实现C++方法的类在cc文件的开头, 这个结构体里:**

    typedef struct {
      PyObject_HEAD
      ActivePyModules *py_modules;
      ActivePyModule *this_module;
    } BaseMgrModule;

**定义pybind规范的class结构:**

    PyTypeObject BaseMgrModuleType = {
      PyVarObject_HEAD_INIT(NULL, 0)
      "ceph_module.BaseMgrModule", /* tp_name */
      sizeof(BaseMgrModule),     /* tp_basicsize */
      0,                         /* tp_itemsize */
      0,                         /* tp_dealloc */
      0,                         /* tp_print */
      0,                         /* tp_getattr */
      0,                         /* tp_setattr */
      0,                         /* tp_compare */
      0,                         /* tp_repr */
      0,                         /* tp_as_number */
      0,                         /* tp_as_sequence */
      0,                         /* tp_as_mapping */
      0,                         /* tp_hash */
      0,                         /* tp_call */
      0,                         /* tp_str */
      0,                         /* tp_getattro */
      0,                         /* tp_setattro */
      0,                         /* tp_as_buffer */
      Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE,        /* tp_flags */
      "ceph-mgr Python Plugin", /* tp_doc */
      0,                         /* tp_traverse */
      0,                         /* tp_clear */
      0,                         /* tp_richcompare */
      0,                         /* tp_weaklistoffset */
      0,                         /* tp_iter */
      0,                         /* tp_iternext */
      BaseMgrModule_methods,     /* tp_methods */
      0,                         /* tp_members */
      0,                         /* tp_getset */
      0,                         /* tp_base */
      0,                         /* tp_dict */
      0,                         /* tp_descr_get */
      0,                         /* tp_descr_set */
      0,                         /* tp_dictoffset */
      (initproc)BaseMgrModule_init,                         /* tp_init */
      0,                         /* tp_alloc */
      BaseMgrModule_new,     /* tp_new */
    };

**定义pybind导出的方法：**

    PyMethodDef BaseMgrModule_methods[] = {
      {"_ceph_get", (PyCFunction)ceph_state_get, METH_VARARGS,
      "Get a cluster object"},

      {"_ceph_get_server", (PyCFunction)ceph_get_server, METH_VARARGS,
      "Get a server object"},

      {"_ceph_get_metadata", (PyCFunction)get_metadata, METH_VARARGS,
      "Get a service's metadata"},

      {"_ceph_get_daemon_status", (PyCFunction)get_daemon_status, METH_VARARGS,
      "Get a service's status"},

      {"_ceph_send_command", (PyCFunction)ceph_send_command, METH_VARARGS,
      "Send a mon command"},

      {"_ceph_set_health_checks", (PyCFunction)ceph_set_health_checks, METH_VARARGS,
      "Set health checks for this module"},

      {"_ceph_get_mgr_id", (PyCFunction)ceph_get_mgr_id, METH_NOARGS,
      "Get the name of the Mgr daemon where we are running"},

      {"_ceph_get_option", (PyCFunction)ceph_option_get, METH_VARARGS,
      "Get a native configuration option value"},

      {"_ceph_get_module_option", (PyCFunction)ceph_get_module_option, METH_VARARGS,
      "Get a module configuration option value"},

      {"_ceph_get_store_prefix", (PyCFunction)ceph_store_get_prefix, METH_VARARGS,
      "Get all KV store values with a given prefix"},

      {"_ceph_set_module_option", (PyCFunction)ceph_set_module_option, METH_VARARGS,
      "Set a module configuration option value"},

      {"_ceph_get_store", (PyCFunction)ceph_store_get, METH_VARARGS,
      "Get a stored field"},

      {"_ceph_set_store", (PyCFunction)ceph_store_set, METH_VARARGS,
      "Set a stored field"},

      {"_ceph_get_counter", (PyCFunction)get_counter, METH_VARARGS,
        "Get a performance counter"},

      {"_ceph_get_latest_counter", (PyCFunction)get_latest_counter, METH_VARARGS,
        "Get the latest performance counter"},

      {"_ceph_get_perf_schema", (PyCFunction)get_perf_schema, METH_VARARGS,
        "Get the performance counter schema"},

      {"_ceph_log", (PyCFunction)ceph_log, METH_VARARGS,
      "Emit a (local) log message"},

      {"_ceph_cluster_log", (PyCFunction)ceph_cluster_log, METH_VARARGS,
      "Emit a cluster log message"},

      {"_ceph_get_version", (PyCFunction)ceph_get_version, METH_NOARGS,
      "Get the ceph version of this process"},

      {"_ceph_get_release_name", (PyCFunction)ceph_get_release_name, METH_NOARGS,
      "Get the ceph release name of this process"},

      {"_ceph_get_context", (PyCFunction)ceph_get_context, METH_NOARGS,
        "Get a CephContext* in a python capsule"},

      {"_ceph_get_osdmap", (PyCFunction)ceph_get_osdmap, METH_NOARGS,
        "Get an OSDMap* in a python capsule"},

      {"_ceph_set_uri", (PyCFunction)ceph_set_uri, METH_VARARGS,
        "Advertize a service URI served by this module"},

      {"_ceph_have_mon_connection", (PyCFunction)ceph_have_mon_connection,
        METH_NOARGS, "Find out whether this mgr daemon currently has "
                    "a connection to a monitor"},

      {"_ceph_update_progress_event", (PyCFunction)ceph_update_progress_event,
      METH_VARARGS, "Update status of a progress event"},
      {"_ceph_complete_progress_event", (PyCFunction)ceph_complete_progress_event,
      METH_VARARGS, "Complete a progress event"},
      {"_ceph_clear_all_progress_events", (PyCFunction)ceph_clear_all_progress_events,
      METH_NOARGS, "Clear all progress events"},

      {"_ceph_dispatch_remote", (PyCFunction)ceph_dispatch_remote,
        METH_VARARGS, "Dispatch a call to another module"},

      {"_ceph_add_osd_perf_query", (PyCFunction)ceph_add_osd_perf_query,
        METH_VARARGS, "Add an osd perf query"},

      {"_ceph_remove_osd_perf_query", (PyCFunction)ceph_remove_osd_perf_query,
        METH_VARARGS, "Remove an osd perf query"},

      {"_ceph_get_osd_perf_counters", (PyCFunction)ceph_get_osd_perf_counters,
        METH_VARARGS, "Get osd perf counters"},

      {"_ceph_is_authorized", (PyCFunction)ceph_is_authorized,
        METH_VARARGS, "Verify the current session caps are valid"},

      {"_ceph_register_client", (PyCFunction)ceph_register_client,
        METH_VARARGS, "Register RADOS instance for potential blacklisting"},

      {"_ceph_unregister_client", (PyCFunction)ceph_unregister_client,
        METH_VARARGS, "Unregister RADOS instance for potential blacklisting"},

      {NULL, NULL, 0, NULL}
    };


**pybind接口， 用于接收和解析python参数 what，并调用C++方法 self->py_modules->get_python 来实现真正的功能：**

    static PyObject*
    ceph_state_get(BaseMgrModule *self, PyObject *args)
    {
      char *what = NULL;
      if (!PyArg_ParseTuple(args, "s:ceph_state_get", &what)) {
        return NULL;
      }

      return self->py_modules->get_python(what);
    }

## Mgr初始化流程及线程模型
Mgr基于多线程架构设计， 主线程初始化完成后保持阻塞等待退出

主线程调用MgrStandby->init()进行环境初始化

### Initialize Messenger
Messenger是Mgr服务的消息总线， 各个模块可以将自己添加到Messenger队列的头尾，订阅Mgr的各种消息

    // Initialize Messenger
    client_messenger->add_dispatcher_tail(this);
    client_messenger->add_dispatcher_head(&objecter);
    client_messenger->add_dispatcher_tail(&client);
    client_messenger->start();

### Initialize MonClient
MonClient连接并认证mon服务，，初始化了一个mgr类型的Messenger，连接成功后启动timer进行定时调度，与mon服务进行双向通讯, 接收消息并处理, 诸如注册py_module模块，向所有py_module推送通知等操作， timer是一个基于线程的定时器

    // Initialize MonClient
    if (monc.build_initial_monmap() < 0) {
      client_messenger->shutdown();
      client_messenger->wait();
      return -1;
    }

### Initialize MgrClient
MgrClient连接并认证Mgr服务，初始化了一个mgr类型的Messenger， 监听有关mgr消息, 主要是MSG_MGR_MAP、MSG_MGR_CONFIGURE、MSG_MGR_CLOSE、MSG_COMMAND_REPLY、MSG_MGR_COMMAND_REPLY.

    mgrc.init();
    client_messenger->add_dispatcher_tail(&mgrc);

### Initialize python plugin
插件加载由MgrStandby开始， 每个python plugin单独一个线程进行加载保持

MgrStandby.cc

    void MgrStandby::handle_mgr_map(ref_t<MMgrMap> mmap) {
      ...
      if (map.active_gid != 0 && map.active_name != g_conf()->name.get_id()) {
        // I am the standby and someone else is active, start modules
        // in standby mode to do redirects if needed
        if (!py_module_registry.is_standby_running()) {
          py_module_registry.standby_start(monc, finisher); // 这里运行启动python plugin
        }
      }
    }

PyModuleRegistry.cc

    void PyModuleRegistry::standby_start(MonClient &mc, Finisher &f) {
      ...
      standby_modules.reset(new StandbyPyModules(
        mgr_map, module_config, clog, mc, f));
      ...
      if (i.second->pStandbyClass) {
        dout(4) << "starting module " << i.second->get_name() << dendl;
        standby_modules->start_one(i.second); //此处开始启动python plugin 的调用
      } else {
        dout(4) << "skipping module '" << i.second->get_name() << "' because "
                  "it does not implement a standby mode" << dendl;
      }
    }

StandbyPyModules.cc

    void StandbyPyModules::start_one(PyModuleRef py_module) {
      std::lock_guard l(lock);
      const 
       name = py_module->get_name();
      
       standby_module = new StandbyPyModule(state, py_module, clog);

      // Send all python calls down a Finisher to avoid blocking
      // C++ code, and avoid any potential lock cycles.
      finisher.queue(new LambdaContext([this, standby_module, name](int) {
        int r = standby_module->load();
        if (r != 0) {
          derr << "Failed to run module in standby mode ('" << name << "')"
              << dendl;
          delete standby_module;
        } else {
          std::lock_guard l(lock);
          
           em = modules.emplace(name, standby_module);
          ceph_assert(em.second); // actually inserted

          dout(4) << "Starting thread for " << name << dendl;
          standby_module->thread.create(standby_module->get_thread_name()); //启动线程，StandbyPyModule是PyModuleRunner的子类， 最终会在启动线程之后在线程函数里调用PyModuleRunner::serve()
        }
      }));
    }

PyModuleRunner.cc

    int PyModuleRunner::serve() {
      ceph_assert(pClassInstance != nullptr);

      // This method is called from a separate OS thread (i.e. a thread not
      // created by Python), so tell Gil to wrap this in a new thread state.
      Gil gil(py_module->pMyThreadState, true);

      // 此处开始调用python plugin模块，执行plugin里的逻辑
       pValue = PyObject_CallMethod(pClassInstance,
          const_cast<char*>("serve"), nullptr);

      int r = 0;
      if (pValue != NULL) {
        Py_DECREF(pValue);
      } else {
        // This is not a very informative log message because it's an
        // unknown/unexpected exception that we can't say much about.


        // Get short exception message for the cluster log, before
        // dumping the full backtrace to the local log.
        std::string exc_msg = peek_pyerror();
        
        clog->error() << "Unhandled exception from module '" << get_name()
                      << "' while running on mgr." << g_conf()->name.get_id()
                      << ": " << exc_msg;
        derr << get_name() << ".serve:" << dendl;
        derr << handle_pyerror() << dendl;

        py_module->fail(exc_msg);

        return -EINVAL;
      }

      return r;
    }



