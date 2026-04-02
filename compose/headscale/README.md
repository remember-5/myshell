# 组网
仓库地址: https://github.com/juanfont/headscale  
example configuration https://github.com/juanfont/headscale/blob/main/config-example.yaml

## 初始化 headscale 和 headscale-ui

headscale 和 headscale-ui 之间的通讯是通过 API 进行的，因此我们需要给 headscale 申请一个有效的 APIKey，命令如下：


其中，参数 720d 是指我们需要创建一个有效期为 720 天的 APIKey，请妥善保存生成的APIKey
```bash
docker compose exec headscale headscale apikeys create -e 720d
```


创建一个用户
```bash
docker compose exec headscale headscale namespaces create main
```

上面的命令创建了一个 main 用户，并为 main 用户创建了一个实效为 24 小时的 preauth-key 最后，进入你的 headsclale-ui 的页面，填入正确的 APIKey 和 hostname，私有的控制台就部署成功了

```bash
docker compose exec headscale headscale nodes register --user main --key mkey:xxx
docker compose exec headscale headscale nodes register --user main --key mkey:xxx
```

## 客户端安装(tailscale)

### linux
download url https://pkgs.tailscale.com/stable/

binaries https://dl.tailscale.com/stable/tailscale_1.68.1_amd64.tgz


```shell
tar zxvf tailscale_1.68.1_amd64.tgz && cd tailscale_1.68.1_amd64
cp tailscaled /usr/sbin/tailscaled
cp tailscale /usr/bin/tailscale
# system D service
cp systemd/tailscaled.service /lib/systemd/system/tailscaled.service
# 配置文件
cp systemd/tailscaled.defaults /etc/default/tailscaled

# 设置开机自启
systemctl enable --now tailscaled
# 查看状态
systemctl status tailscaled


# 注册
tailscale up --login-server=http://<HEADSCALE_PUB_ENDPOINT>:8080 --accept-routes=true --accept-dns=false
```








# FAQ
- headscale 提示没有权限的话，就加上`user: root`
- url后面加上`/apple` 可以进入apple安装guide

# 参考
- [headscale私有部署](https://junyao.tech/posts/e8e7dd51.html)
- [headscale-ui](https://github.com/gurucomputing/headscale-ui/blob/master/documentation/configuration.md)
- [[译] NAT 穿透是如何工作的：技术原理及企业级实践（Tailscale, 2020）](https://arthurchiao.art/blog/how-nat-traversal-works-zh/)




