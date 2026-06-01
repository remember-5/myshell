## 目的

<!-- 简洁说明这个 merge request 要解决什么问题。 -->

## 关联工单

<!--
如果合并后需要自动关闭 issue，使用：
Closes #123

如果只是关联，不自动关闭 issue，使用：
Related to #123

跨项目示例：
Closes group/project#123
-->

Related to #

## 改动内容

<!-- 列出主要改动点，面向 reviewer 说明发生了什么变化。 -->

-
-
-

## 影响范围

<!-- 勾选本次改动涉及的范围。 -->

- [ ] Frontend
- [ ] Backend
- [ ] API
- [ ] Database
- [ ] CI/CD
- [ ] Build
- [ ] Deploy / Infra
- [ ] Documentation
- [ ] Test
- [ ] Other:

## 测试验证

<!-- 写清楚你做了哪些验证；没有测试需要说明原因。 -->

- [ ] 本地验证通过
- [ ] 单元测试通过
- [ ] 集成测试通过
- [ ] CI 通过
- [ ] 已验证回归场景
- [ ] 不涉及测试，原因：

验证说明：

```text
```

## 发布说明
<!--
面向用户、业务方或运维说明本次变化。
这段可以作为 release note 的人工参考。
-->


## Changelog
<!--
必须确保下面的 trailers 出现在最终 commit message 中。
如果使用 squash merge，请把它们保留在 squash commit message 末尾。

Changelog 可选值需要匹配 .gitlab/changelog_config.yml：

feat      Features
fix       Bug Fixes
build     Build System
chore     Maintenance
ci        Continuous Integration
docs      Documentation
style     Style Changes
refactor  Code Refactoring
perf      Performance Improvements
test      Testing

Issue 建议填写完整 issue URL，因为当前 changelog_config.yml 会把它渲染成链接。
MR 通常 GitLab 会自动识别，不必手动填写；只有自动识别失败时再填完整 MR URL。
-->

Changelog: feat
Issue: https://gitlab.example.com/group/project/-/issues/123

## 风险与回滚
<!-- 有线上影响、数据变更、配置变更、兼容性风险时必须填写。 -->

风险：

回滚方式：

## 其他信息
<!-- 截图、日志、设计稿、接口文档、部署注意事项等。 -->