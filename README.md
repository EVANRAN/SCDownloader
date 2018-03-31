# SCDownloadDemo

> 这只是一个脑洞。


### 概况：

1. 占用内存

    下载大文件采用某种方式会导致内存增高，用 `NSOutStream` 配合 `NSURLSessionDataTask` 来下载。
2. 自定义下载并发量
 
    通过自定义 `NSOperation`, 自定义其执行、完成状态，让`NSOperationQueue` 来控制并发。
    如暂停后，判定其operation finished, 下面的任务就会替补上来。
   
3. 断点续传

    暂停下载任务 dataTask， 由于很快就会超时，无法调用 `[task resume]` ， 所以这里暂停就 取消此task 并让此 `operation`达到完成状态。 点继续会重新创建并填加一个 `operation`。以实现让queue来控制并发。但是重新添加operation会添加到queue的最后面，为了让其还能优先下载， 这里改变了其 `opeartaion` 的 `priority`。
 离线仅仅Cache了url 的 total-length，通过计算已下载内容的 length，相等就不会再创建 `operation`。

### Tip
有诸多地方没有完善，仅提供一个思路。



