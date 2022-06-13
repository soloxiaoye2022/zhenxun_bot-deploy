# zhenxun_bot-deploy
 真寻bot一键部署脚本
## 食用方法
```bash
bash <(curl -s -L http://gitee.com/soloxiaoye/zhenxun_bot_tool/blob/master/install.sh)
```
## 更新

****

**2022/6/12**

* 修改安装目录为/sd/bot

**2022/6/11**

* 添加对新版虚拟环境的支持
* 修改脚本为仅支持在手机运行termux内的proot容器运行的Ubuntu20.04/dldebian11系统使用

****以下更新内容为原作者*****

**2022/05/21**

* 修复bug [#15](https://github.com/zhenxun-org/zhenxun_bot-deploy/issues/15)

**2022/05/20**

* 更改监听端口为14514
* 添加卸载二次验证 [#12](https://github.com/zhenxun-org/zhenxun_bot-deploy/issues/12)

**2022/05/18** [v1.0.4]

* 添加切换git源功能
* 添加卸载功能
* 显示安装时长
* 修改pip源使用方式
* 修改安装目录为/home