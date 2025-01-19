# OfflineInsiderEnroll 

![OfflineInsiderEnroll 的截图](https://i.imgur.com/90s1hli.png)

## 介绍

OfflineInsiderEnroll 是一个简单的 Windows 命令提示符脚本，用于在未使用 Microsoft 帐户登录的计算机上加入 Windows 预览体验计划。

此脚本仅与 Windows 11 或 Windows 10 版本 1809 及更高版本兼容。

## 使用方法

此脚本需要管理员权限才能运行。您只需右键单击它并 > `以管理员身份运行`。

### 安装和配置更改

启动后，脚本会提供 __*Windows 预览体验计划*__ 频道的选项。
要进行选择，请按与所选选项对应的字母，然后按回车。

如果机器未注册预览体验计划，系统将提示您重新启动电脑以启用 *`Windows 预览体验计划`* 所需的 *`Microsoft Flight 签名`*


**注意:** Windows 预览体验计划要求将诊断数据收集设置为 *`完整`*。
将您的电脑注册到 *Windows Insider 计划* 后，请确保您的诊断数据收集设置已设置为 *`完整`*。如果您没有正确设置，某些 `预览体验` 版本可能无法在 *`Windows 更新`* 中提供。
您可以按如下方式验证或修改遥测设置：

__Windows 11__: *`设置`* > *`隐私和安全性`* > *`诊断和反馈`*

__Windows 10__: *`设置`* > *`隐私`* > *`诊断和反馈`*

### 将 Windows 预览体验计划恢复为默认选项

要将 *`Windows 预览体验计划`* 恢复为默认设置，只需在 `OfflineInsiderEnroll 脚本` 中选择 `停止接收 Windows 预览体验计划内部版本`。系统将提示您重新启动，因为此选项将禁用 *`Microsoft Flight 签名`*。

## 这是如何运作的？

此脚本利用了未公开的 `TestFlags`注册表值。
如果将此值设置为`0x20`，则对在线 *Windows 预览体验计划*服务的所有访问都将被禁用。因此，我们可以设置自己的 *Windows 预览体验计划*值，而不会被 Windows 预览体验计划服务的数据覆盖。而且因为 `Windows Update` 不会检查电脑是否真的注册到预览体验计划，所以只需在注册表中设置正确的值，即可获得*预览体验计划*版本。

## 许可

该项目采用 MIT 许可证。详情请参阅 `LICENSE`。
