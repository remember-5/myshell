## 新版本
`docker-compose.new.yml`

## 旧版本
`docker-compose.old.yml`


- minio在 `2022-10-24T18-35-07Z` 版本之后，不再支持单实例多驱动的模式，如果之前是采用了多驱动的方式，则需要改一下minio的运行方式
- minio在 `2025-04-22T22-12-26Z` 版本后，web console被砍，如果用web console,请采用这个版本

## 创建新用户和桶

1. create bucket: Buckets ->  create bucket

2. create user: identity -> users -> create user -> input username and password (don't select policy)

3. create policy: Polices -> create policy -> input policy name and description (please change "Statement.Resource" to "arn:aws:s3:::{bucket_name}") -> save


```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject", // 允许下载对象
                "s3:ListBucket", // 允许列出桶内容
                "s3:PutObject" // 允许上传对象
            ],
            "Resource": [
                "arn:aws:s3:::yfk",  // 桶级权限
                "arn:aws:s3:::yfk/*"  // 允许所有目录

            ]
        }
    ]
}
```

https://min.io/docs/minio/linux/administration/identity-access-management/policy-based-access-control.html

4. Anonymous Access: Buckets -> anonymous access

官方默认的是有列出List Object的权限，可以精简为这样

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "*"
                ]
            },
            "Action": [
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::yfk/public/**"
            ]
        }
    ]
}

```

官方的
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "*"
                ]
            },
            "Action": [
                "s3:GetBucketLocation"
            ],
            "Resource": [
                "arn:aws:s3:::yfk"
            ]
        },
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "*"
                ]
            },
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::yfk"
            ],
            "Condition": {
                "StringEquals": {
                    "s3:prefix": [
                        "public/*"
                    ]
                }
            }
        },
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "*"
                ]
            },
            "Action": [
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::yfk/public/**"
            ]
        }
    ]
}

```



5. get AK/SK: login by user -> get access key



## nginx代理私有桶的加签链接



```
http {
    
    #proxy_set_header Host $host;
    # 设置Host头为OSS的endpoint（域名）
    # 因为有私有的文件，需要重写请求头，避免出现验签失败
    proxy_set_header Host "172.43.51.62";
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Port $server_port;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";

    # oss
    location ^~ / {
        proxy_pass https://172.43.51.62$request_uri;
    }
}


```

