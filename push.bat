@echo off
REM ===== 研擎 NebulaLab 一键推送 GitHub =====
REM 用法：先在 github.com 上新建一个空仓库(不要勾选README)，然后把下面的 URL 换成你的仓库地址
set REPO_URL=https://github.com/你的用户名/nebulalab.git
git remote add origin %REPO_URL%
git push -u origin main
echo 推送完成！到仓库 Settings ^> Pages 选择 main 分支即可开通官网页面
pause
