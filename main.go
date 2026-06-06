package main

import (
	"embed"
	"fmt"
	"io"
	"io/fs"
	"mime"
	"net"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"time"
)

//go:embed dist
var distFS embed.FS

func findFreePort() int {
	l, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		return 3456
	}
	defer l.Close()
	return l.Addr().(*net.TCPAddr).Port
}

func openBrowser(url string) {
	time.Sleep(400 * time.Millisecond)
	switch runtime.GOOS {
	case "windows":
		exec.Command("rundll32", "url.dll,FileProtocolHandler", url).Start()
	case "darwin":
		exec.Command("open", url).Start()
	default:
		exec.Command("xdg-open", url).Start()
	}
}

func serveFile(w http.ResponseWriter, path string) {
	data, err := distFS.ReadFile("dist/" + path)
	if err != nil {
		http.Error(w, "not found", 404)
		return
	}
	ext := filepath.Ext(path)
	if ct := mime.TypeByExtension(ext); ct != "" {
		w.Header().Set("Content-Type", ct)
	}
	w.Header().Set("Cache-Control", "public, max-age=31536000")
	w.WriteHeader(200)
	w.Write(data)
}

func serveIndex(w http.ResponseWriter) {
	f, err := distFS.Open("dist/index.html")
	if err != nil {
		http.Error(w, "index.html not found", 500)
		return
	}
	defer f.Close()
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.Header().Set("Cache-Control", "no-cache")
	w.WriteHeader(200)
	io.Copy(w, f)
}

func handler(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/")

	if path == "" {
		serveIndex(w)
		return
	}

	// Проверяем, существует ли статический файл
	_, err := fs.Stat(distFS, "dist/"+path)
	if err == nil {
		// Файл существует — отдаём его
		serveFile(w, path)
		return
	}

	// Файл не найден — SPA fallback: отдаём index.html
	serveIndex(w)
}

func main() {
	port := findFreePort()
	addr := fmt.Sprintf("127.0.0.1:%d", port)
	url := fmt.Sprintf("http://%s", addr)

	mux := http.NewServeMux()
	mux.HandleFunc("/", handler)

	go openBrowser(url)

	fmt.Printf("Декоратор запущен: %s\n", url)
	if err := http.ListenAndServe(addr, mux); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
