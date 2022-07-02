# zhenxun_bot-deploy
 真寻bot一键部署脚本
## 食用方法
UTermux/ZeroTermux/TermuxWatch下载站https://blog.utermux.dev/ut/download.html
zerotermux下载地址https://d.icdown.club/repository/main/ZeroTermux/ZeroTermux%20-0.118.21.apk
视频教程和软件下载地址https://quqi.avyeld.com/s/7472431/hwa9q8OUfjCIN721
## 一键脚本
```bash
bash <(curl -s -L https://raw.githubusercontent.com/soloxiaoye2022/zhenxun_bot-deploy/main/install.sh)
```
## 更新

****


**2022/7/2**

* 修改安装目录为/root 
* 添加脚本升级链接
* 修改dns，解决部分本地dns无法访问api.github.com问题
* 支持proot容器安装ssh服务

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
