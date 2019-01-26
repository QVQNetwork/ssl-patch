# Nginx 防止SSL嗅探

此方案利用Nginx stream中的ssl_preread模块来识别ClientHello中的SNI信息，以防止SSL嗅探。

redirector.conf: 在 main 语境中引载使用 (main {...})

upstream.conf: 在redirector.conf中引载 (或在 stream 语境中使用 (stream{...})

web_server.conf: 你的网站配置示例
