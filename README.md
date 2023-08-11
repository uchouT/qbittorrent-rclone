# qbittorrent-rclone

## 前言

原地址：[【更新分享率控制】qBittorrent + Rclone 自动上传脚本](https://hostloc.com/thread-612238-1-1.html)
此项目仅作备份自用

1. 通过添加标签或者分类，再添加定时任务，可以指定种子分享率达到期望值再删除数据，避免吸血。请自行安装jq
2. 确保两个脚本的auto_del_flag变量一致，否则没办法删除分享率达标的种子
   只吸血的同学只需要将qu_auto.sh的leeching_mode设为true即可。
   需要控制分享率的需要两个脚本
   并添加监控任务:
```
*/1 * * * * bash /root/ratio_mon.sh
```
## 修改的内容

rclone的保存路径与种子在服务器上的下载路径一致，且单文件种子上传时会在目标路径创建文件夹，方便结合qbittorrent rss下载番剧

## 使用方法

1. Qb WEB UI勾选`torrent完成时运行外部程序`，填上：

```
bash /root/qb_auto.sh  "%N" "%F" "%R" "%D" "%C" "%Z" "%I"
```
![](https://raw.githubusercontent.com/uchouT/qbittorrent-rclone/main/pic/Mvmv5j.jpg)

2. ```
   chmod +x qb_auto.sh
   ```

   