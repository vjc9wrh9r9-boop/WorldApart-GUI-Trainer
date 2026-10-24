package main

import (
	"archive/zip"
	"bytes"
	_ "embed"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"
	"unsafe"
)

//go:embed res.zip
var resZip []byte

var (
	user32 = syscall.NewLazyDLL("user32.dll")
	msgBox = user32.NewProc("MessageBoxW")
)

func messageBox(title, text string) {
	t, _ := syscall.UTF16PtrFromString(title)
	m, _ := syscall.UTF16PtrFromString(text)
	msgBox.Call(0, uintptr(unsafe.Pointer(m)), uintptr(unsafe.Pointer(t)), 0x10)
}

func extract(data []byte, dest string) error {
	zr, err := zip.NewReader(bytes.NewReader(data), int64(len(data)))
	if err != nil {
		return err
	}
	cleanDest := filepath.Clean(dest)
	for _, f := range zr.File {
		target := filepath.Join(dest, filepath.FromSlash(f.Name))
		cleanTarget := filepath.Clean(target)
		if cleanTarget != cleanDest && !strings.HasPrefix(cleanTarget, cleanDest+string(os.PathSeparator)) {
			continue
		}
		if f.FileInfo().IsDir() {
			os.MkdirAll(cleanTarget, 0755)
			continue
		}
		if err := os.MkdirAll(filepath.Dir(cleanTarget), 0755); err != nil {
			return err
		}
		rc, err := f.Open()
		if err != nil {
			return err
		}
		out, err := os.Create(cleanTarget)
		if err != nil {
			rc.Close()
			return err
		}
		_, err = io.Copy(out, rc)
		out.Close()
		rc.Close()
		if err != nil {
			return err
		}
	}
	return nil
}

func main() {
	appDir := filepath.Join(os.Getenv("LOCALAPPDATA"), "BWFMod")
	if os.Getenv("LOCALAPPDATA") == "" {
		appDir = filepath.Join(os.Getenv("TEMP"), "BWFMod")
	}
	rtDir := filepath.Join(appDir, "runtime")
	stamp := filepath.Join(appDir, "v1.stamp")
	hostExe := filepath.Join(rtDir, "mzhost.exe")
	ctFile := filepath.Join(rtDir, "不问凡尘-缤纷颜色-V1.CT")

	if _, err := os.Stat(stamp); err != nil {
		os.RemoveAll(rtDir)
		if err := extract(resZip, rtDir); err != nil {
			messageBox("不问凡尘修改器", "初始化失败："+err.Error())
			return
		}
		os.WriteFile(stamp, []byte("1"), 0644)
	}

	cmd := exec.Command(hostExe, ctFile)
	cmd.Dir = rtDir
	if err := cmd.Start(); err != nil {
		messageBox("不问凡尘修改器", "启动失败："+err.Error())
	}
}
