# Nginx Prevent SSL sniffing
## [中文说明](https://github.com/QVQNetwork/ssl-patch/blob/master/nginx-config-nosni/README-zh_cn.md)

This method uses the ssl_preread module in Nginx stream to identify the SNI information in ClientHello to prevent SSL sniffing.

redirector.conf: include in main context (main {...})
upstream.conf: include in redirector.conf (or stream context (stream{...})
web_server.conf: your website configuration example
