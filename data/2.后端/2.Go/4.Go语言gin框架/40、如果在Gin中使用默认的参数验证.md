### Gin框架中validator库的验证参数属性

在Gin框架中，参数验证主要通过`github.com/go-playground/validator/v10`库实现。

除了常用的`binding:"required"`外，validator库还提供了丰富的验证规则，可满足各种复杂的参数验证需求。

### 基础验证规则

1. **存在性验证**
   ```go
   Name  string `json:"name" binding:"required"`         // 必传，且不为空字符串
   Email string `json:"email" binding:"omitempty,email"`  // 可选，若存在则必须为有效邮箱
   ```

2. **数值范围验证**
   ```go
   Age    int    `json:"age" binding:"min=1,max=150"`    // 年龄必须在1-150之间
   Height float64 `json:"height" binding:"omitempty,gt=0"` // 可选，若存在则必须大于0
   ```

3. **长度验证**
   ```go
   Password string `json:"password" binding:"min=6,max=20"` // 密码长度必须在6-20之间
   Phone    string `json:"phone" binding:"len=11"`          // 手机号长度必须为11位
   ```

4. **正则表达式验证**
   ```go
   IDCard string `json:"id_card" binding:"omitempty,regexp=^[1-9]\\d{5}(18|19|20)\\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\\d|3[01])\\d{3}[0-9Xx]$"` // 身份证号格式
   ```

### 字符串相关验证

1. **格式验证**
   ```go
   Email     string `json:"email" binding:"omitempty,email"`            // 邮箱格式
   URL       string `json:"url" binding:"omitempty,url"`                // URL格式
   IP        string `json:"ip" binding:"omitempty,ip"`                  // IP地址格式
   UUID      string `json:"uuid" binding:"omitempty,uuid"`              // UUID格式
   CreditCard string `json:"credit_card" binding:"omitempty,creditcard"` // 信用卡号格式
   ```

2. **内容验证**
   ```go
   Username  string `json:"username" binding:"alphanum"`                 // 只能包含字母和数字
   Nickname  string `json:"nickname" binding:"alphaunicode"`             // 只能包含Unicode字母
   Address   string `json:"address" binding:"printascii"`                // 只能包含可打印ASCII字符
   ```

3. **枚举值验证**
   ```go
   Gender    string `json:"gender" binding:"oneof=male female other"`    // 只能是male/female/other中的一个
   Role      string `json:"role" binding:"omitempty,isdefault|admin|user"` // 可选，若存在则只能是isdefault/admin/user中的一个
   ```

### 集合与结构验证

1. **切片/数组验证**
   ```go
   Hobbies   []string `json:"hobbies" binding:"dive,required,min=2,max=10"` // 切片元素必传，长度2-10
   Scores    []int    `json:"scores" binding:"dive,min=0,max=100"`            // 切片元素必须在0-100之间
   ```

2. **映射验证**
   ```go
   Metadata  map[string]string `json:"metadata" binding:"dive,keys,alphanum,dive,required"` // 键为字母数字，值必传
   ```

3. **结构体嵌套验证**
   ```go
   Profile   Profile `json:"profile" binding:"required"` // 嵌套结构体必传
   
   // Profile 结构体
   type Profile struct {
       City    string `json:"city" binding:"required"`
       ZipCode string `json:"zip_code" binding:"omitempty,len=6"`
   }
   ```

4. **指针验证**
   ```go
   Age       *int    `json:"age" binding:"omitempty,min=1,max=150"` // 指针类型，若不为nil则值在1-150之间
   ```

### 条件验证

1. **依赖验证**
   ```go
   // 当Type为"email"时，Email必传
   Type      string `json:"type" binding:"oneof=email phone"`
   Email     string `json:"email" binding:"required_if=Type email,email"`
   Phone     string `json:"phone" binding:"required_if=Type phone,len=11"`
   ```

2. **互斥验证**
   ```go
   // Email和Phone至少一个必传
   Email     string `json:"email" binding:"omitempty,email"`
   Phone     string `json:"phone" binding:"omitempty,len=11"`
   binding:"required_without=Email Phone" // 结构体标签
   ```

3. **相等验证**
   ```go
   // 两次密码必须一致
   Password  string `json:"password" binding:"required,min=6"`
   Confirm   string `json:"confirm" binding:"required,eqfield=Password"`
   ```

