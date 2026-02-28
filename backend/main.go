package main

import (
	"god-board/db"
	"god-board/router"
)

func main() {
	// 初始化数据库
	db.InitDB()

	// 启动服务器
	router.RunServer()
}
