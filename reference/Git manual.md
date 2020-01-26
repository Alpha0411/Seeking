# Git使用方法说明

## 安装Git
从[**Git官网**](https://git-scm.com/)下载最新版本的Git安装包，然后按照默认配置进行安装。

## 配置Git
安装完成后，新建一个文件夹作为本地仓库，在文件夹中右键点击"Git Bash here"，打开Git Bash。

然后在Git Bash中输入以下命令设置Git用户名: (其中--global命令使其适用于该电脑上的每个仓库)  
```
$ git config --global user.name "Mona Lisa"
```

确认当前用户名设置正确：  
```
$ git config --global user.name
> Mona Lisa
```

在Git Bash中输入以下命令设置邮件地址:
```
$ git config --global user.email "email@example.com"
```

确认当前邮件地址设置正确：
```
$ git config --global user.email
> email@example.com
```

通过[**设置上传邮件地址**](https://help.github.com/en/github/setting-up-and-managing-your-github-user-account/setting-your-commit-email-address)添加邮件地址到GitHub账户，之后就可以通过Git在GitHub上进行操作。

## GitHub连接错误解决方案
使用Git克隆GitHub上的仓库时，报错如下：
```
Cloning into 'rest-client'... 
fatal: unable to access 'https://github.com/******.git/': Failed to connect to github.com port 443: Timed out 
```

根本原因是GitHub被墙，使用了代理，但Git没有设置。  
在Git Bash中输入以下命令设置全局代理：
```
git config --global http.proxy 127.0.0.1:1080
```

设置完后就可以正常访问GitHub。