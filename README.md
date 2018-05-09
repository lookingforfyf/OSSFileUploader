# ZOSSFileUploader

ios 阿里云SDK 上传图片、文件。 

可以支持多个文件、支持总进度回调、采用文件的形式上传，不会导致内存持续增长泄露问题。


注意:工程可以直接模拟上传文件成功，但是上传后链接不能打开。

将代码中的如下参数替换成 自己在阿里云的配置即可。

static NSString *const AccessKey = @"your-key";

static NSString *const SecretKey = @"your-secret";

static NSString *const BucketName = @"your-bucket";

static NSString *const AliYunHost = @"http://oss-cn-shenzhen.aliyuncs.com/";

static NSString *kTempFolder = @"temp";

