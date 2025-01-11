#!/bin/sh
torrent_name=$1
content_dir=$2
root_dir=$3
save_dir=$4
files_num=$5
torrent_size=$6
torrent_hash=$7
torrent_type=$8

qb_version="4.5.4"
qb_username="admin"
qb_password="yourpassword"
qb_web_url="http://localhost:8080"
leeching_mode="false"
log_dir="/root/qblog"
rclone_dest="od"
rclone_parallel="5"
auto_del_flag="rcloned"

if [ ! -d ${log_dir} ]
then
	mkdir -p ${log_dir}
fi

version=$(echo $qb_version | grep -P -o "([0-9]\.){2}[0-9]" | sed s/\\.//g)

function qb_login(){
	if [ ${version} -gt 404 ]
	then
		qb_v="1"
		cookie=$(curl -i --header "Referer: ${qb_web_url}" --data "username=${qb_username}&password=${qb_password}" "${qb_web_url}/api/v2/auth/login" | grep -P -o 'SID=\S{32}')
		if [ -n ${cookie} ]
		then
			echo "[$(date '+%Y-%m-%d %H:%M:%S')] 登录成功！cookie:${cookie}" >> ${log_dir}/autodel.log

		else
			echo "[$(date '+%Y-%m-%d %H:%M:%S')] 登录失败！" >> ${log_dir}/autodel.log
		fi
	elif [[ ${version} -le 404 && ${version} -ge 320 ]]
	then
		qb_v="2"
		cookie=$(curl -i --header "Referer: ${qb_web_url}" --data "username=${qb_username}&password=${qb_password}" "${qb_web_url}/login" | grep -P -o 'SID=\S{32}')
		if [ -n ${cookie} ]
		then
			echo "[$(date '+%Y-%m-%d %H:%M:%S')] 登录成功！cookie:${cookie}" >> ${log_dir}/autodel.log
		else
			echo "[$(date '+%Y-%m-%d %H:%M:%S')] 登录失败" >> ${log_dir}/autodel.log
		fi
	elif [[ ${version} -ge 310 && ${version} -lt 320 ]]
	then
		qb_v="3"
		echo "陈年老版本，请及时升级"
		exit
	else
		qb_v="0"
		exit
	fi
}

function qb_del(){
	if [ ${leeching_mode} == "true" ]
	then
		if [ ${qb_v} == "1" ]
		then
			curl "${qb_web_url}/api/v2/torrents/delete?hashes=${torrent_hash}&deleteFiles=true" --cookie ${cookie}
			echo "[$(date '+%Y-%m-%d %H:%M:%S')] 删除成功！种子名称:${torrent_name}" >> ${log_dir}/qb.log
		elif [ ${qb_v} == "2" ]
		then
			curl -X POST -d "hashes=${torrent_hash}" "${qb_web_url}/command/deletePerm" --cookie ${cookie}
		else
			echo "[$(date '+%Y-%m-%d %H:%M:%S')] 删除成功！种子文件:${torrent_name}" >> ${log_dir}/qb.log
			echo "qb_v=${qb_v}" >> ${log_dir}/qb.log
		fi
	else
		echo "[$(date '+%Y-%m-%d %H:%M:%S')] 不自动删除已上传种子" >> ${log_dir}/qb.log
	fi
}

function rclone_copy(){
	if [ ${type} == "file" ]
	then
		if [ ${torrent_type} == "Bangumi" ]
		then
			sleep 15
			content_dir=$(find "${save_dir}" -type f -size ${torrent_size}c)
		fi
		rclone_copy_cmd=$(rclone -v copy --transfers ${rclone_parallel} --log-file  ${log_dir}/qbauto_copy.log "${content_dir}" ${rclone_dest}:"${save_dir:5}")
	elif [ ${type} == "dir" ]
	then
		rclone_copy_cmd=$(rclone -v copy --transfers ${rclone_parallel} --log-file ${log_dir}/qbauto_copy.log "${content_dir}"/ ${rclone_dest}:"${content_dir:5}"/)
	fi
}

function qb_add_auto_del_tags(){
	if [ ${qb_v} == "1" ]
	then
		curl -X POST -d "hashes=${torrent_hash}&tags=${auto_del_flag}" "${qb_web_url}/api/v2/torrents/addTags" --cookie "${cookie}"
	elif [ ${qb_v} == "2" ]
	then
		curl -X POST -d "hashes=${torrent_hash}&category=${auto_del_flag}" "${qb_web_url}/command/setCategory" --cookie ${cookie}
	else
		echo "qb_v=${qb_v}" >> ${log_dir}/qb.log
	fi
}
if [ ${torrent_type} == "Bangumi" ]
then
	echo "AutoBangumi" >> ${log_dir}/qb.log
fi
if [ -f "${content_dir}" ]
then
   echo "[$(date '+%Y-%m-%d %H:%M:%S')] 类型：文件" >> ${log_dir}/qb.log
   type="file"
   rclone_copy
   qb_login
   qb_add_auto_del_tags
   qb_del
elif [ -d "${content_dir}" ]
then 
   echo "[$(date '+%Y-%m-%d %H:%M:%S')] 类型：目录" >> ${log_dir}/qb.log
   type="dir"
   rclone_copy
   qb_login
   qb_add_auto_del_tags
   qb_del
else
   echo "[$(date '+%Y-%m-%d %H:%M:%S')] 未知类型，取消上传" >> ${log_dir}/qb.log
fi

echo "种子名称：${torrent_name}" >> ${log_dir}/qb.log
echo "内容路径：${content_dir}" >> ${log_dir}/qb.log
echo "根目录：${root_dir}" >> ${log_dir}/qb.log
echo "保存路径：${save_dir}" >> ${log_dir}/qb.log
echo "文件数：${files_num}" >> ${log_dir}/qb.log
echo "文件大小：${torrent_size}Bytes" >> ${log_dir}/qb.log
echo "HASH:${torrent_hash}" >> ${log_dir}/qb.log
echo "Cookie:${cookie}" >> ${log_dir}/qb.log
echo -e "-------------------------------------------------------------\n" >> ${log_dir}/qb.log
