# Spring Boot中配置⽂件的加载顺序是怎样的？

优先级从⾼到低，⾼优先级的配置覆盖低优先级的配置，所有配置会形成互补配置。 

1. **命令⾏参数**。 -> 一定不会被覆盖

2. **Java系统属性**（System.getProperties()）； 

3. 操作系统环境变量 ； 

4. jar包外部的application-`{profile}`.properties或application.yml(带spring.profile)配置⽂件 

5. jar包内部的application-`{profile}`.properties或application.yml(带spring.profile)配置⽂件 再来加载不带profile 

6. jar包外部的`application.properties`或application.yml(不带spring.profile)配置⽂件 

7. jar包内部的application.properties或application.yml(不带spring.profile)配置⽂件 

8. @Configuration注解类上的@PropertySource -> 被覆盖的可能性最大