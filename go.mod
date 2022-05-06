module github.com/zawachte/cluster-api-k3s

go 1.13

require (
	github.com/coredns/corefile-migration v1.0.14
	github.com/go-logr/logr v1.2.0
	github.com/onsi/ginkgo v1.16.5
	github.com/onsi/gomega v1.17.0
	github.com/pkg/errors v0.9.1
	k8s.io/api v0.23.5
	k8s.io/apimachinery v0.23.5
	k8s.io/apiserver v0.23.5
	k8s.io/client-go v0.23.5
	k8s.io/klog/v2 v2.30.0
	k8s.io/utils v0.0.0-20211116205334-6203023598ed
	sigs.k8s.io/cluster-api v1.1.3
	sigs.k8s.io/controller-runtime v0.11.2
	sigs.k8s.io/yaml v1.3.0
)

replace sigs.k8s.io/cluster-api => sigs.k8s.io/cluster-api v1.1.3
