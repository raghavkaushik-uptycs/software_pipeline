package main

import (
	"fmt"
	"time"
)

func main() {
	date := time.Unix(time.Now().Unix(), 0)
	fmt.Println(date)
}
