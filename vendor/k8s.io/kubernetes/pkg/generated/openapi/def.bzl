load("@io_bazel_rules_go//go:def.bzl", "go_library")
load("@io_kubernetes_build//defs:go.bzl", "go_genrule")

def openapi_library(name, tags, srcs, go_prefix, vendor_prefix="", openapi_targets=[], vendor_targets=[]):
  deps = [
      "//vendor/github.com/go-openapi/spec:go_default_library",
      "//vendor/k8s.io/kube-openapi/pkg/common:go_default_library",
  ] + ["//%s:go_default_library" % target for target in openapi_targets] + ["//vendor/%s:go_default_library" % target for target in vendor_targets]
  go_library(
      name=name,
      tags=tags,
      srcs=srcs + [":zz_generated.openapi"],
      deps=deps,
  )
  go_genrule(
      name = "zz_generated.openapi",
      srcs = srcs + ["//" + vendor_prefix + "hack/boilerplate:boilerplate.go.txt"],
      outs = ["zz_generated.openapi.go"],
      cmd = " ".join([
        "$(location //vendor/k8s.io/code-generator/cmd/openapi-gen)",
        "--v 1",
        "--logtostderr",
        "--go-header-file $(location //" + vendor_prefix + "hack/boilerplate:boilerplate.go.txt)",
        "--output-file-base zz_generated.openapi",
        "--output-package " + go_prefix + vendor_prefix + "pkg/generated/openapi",
        "--input-dirs " + ",".join([go_prefix + target for target in openapi_targets] + [go_prefix + "vendor/" + target for target in vendor_targets]),
        "&& cp " + vendor_prefix + "pkg/generated/openapi/zz_generated.openapi.go $(location :zz_generated.openapi.go)",
      ]),
      go_deps = deps,
      tools = ["//vendor/k8s.io/code-generator/cmd/openapi-gen"],
)
