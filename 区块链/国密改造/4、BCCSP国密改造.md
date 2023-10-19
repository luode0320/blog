# 初始化入口改造国密

## nopkcs11

`bccsp/factory/nopkcs11.go`

补充gm实例的加载

## 对比结果

![image-20231019112727604](../../图片保存/image-20231019112727604.png)

## 改造前

```go
func initFactories(config *FactoryOpts) error {
	// Take some precautions on default opts
	if config == nil {
		config = GetDefaultOpts()
	}

	if config.Default == "" {
		config.Default = "SW"
	}

	if config.SW == nil {
		config.SW = GetDefaultOpts().SW
	}

	// Software-Based BCCSP
	if config.Default == "SW" && config.SW != nil {
		f := &SWFactory{}
		var err error
		defaultBCCSP, err = initBCCSP(f, config)
		if err != nil {
			return errors.Wrapf(err, "Failed initializing BCCSP")
		}
	}

	if defaultBCCSP == nil {
		return errors.Errorf("Could not find default `%s` BCCSP", config.Default)
	}

	return nil
}
```

## 改造后

```go
// initFactories 初始化工厂
func initFactories(config *FactoryOpts) error {
	// 如果没有任何自定义配置, 则对默认选项采取一些预防措施
	if config == nil {
		config = GetDefaultOpts()
	}

	if config.Default == "" {
		config.Default = "SW"
	}

	if config.SW == nil {
		config.SW = GetDefaultOpts().SW
	}

	// 加载区块链加密服务提供商工厂
	factory := LoadFactory(config.Default)
	if factory == nil {
		return errors.Errorf("加密服务提供商 %s 无效", config.Default)
	}

	var err error
	// 这就是初始化方法了, 我们知道, 这里只是调用了 get 方法
	// 返回 BCCSP 到全局的变量中, 也就是开始的 defaultBCCSP bccsp.BCCSP
	// 很明显详细的初始化过程根本不在这里
	// 那只能在 get 方法中了, SWFactory的 get 方法中
	defaultBCCSP, err = initBCCSP(factory, config)
	if err != nil {
		return errors.Wrapf(err, "初始化 BCCSP 失败")
	}

	if defaultBCCSP == nil {
		return errors.Errorf("找不到默认值 `%s` BCCSP", config.Default)
	}

	return nil
}
```

补充加载的方法`LoadFactory`: 

```go
// LoadFactory 加载区块链加密服务提供商工厂
func LoadFactory(name string) BCCSPFactory {
    // 补充GMFactory
	factories := []BCCSPFactory{&SWFactory{}, &GMFactory{}}

	for _, factory := range factories {
		if name == factory.Name() {
			return factory
		}
	}

	return nil
}
```

