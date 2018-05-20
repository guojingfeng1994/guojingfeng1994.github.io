---
title: JS中this的指向总结
date: 2017-05-14 02:17:28
categories: 
  - JavaScript
tags:
  - this
  - this指向
---
对于JavaScript函数调用中this的指向，总结起来也就四种绑定规则：

## 默认绑定（Default Binding）

strict mode 下是 undefined，否则就是全局对象。

代码示例：
{% codeblock lang:JavaScript %}
// 非严格模式

function foo() {
	console.log( this.a );
}

var a = 2;

foo(); // 2
{% endcodeblock %}

{% codeblock lang:JavaScript %}
// 严格模式

function foo() {
	"use strict";

	console.log( this.a );
}

var a = 2;

foo(); // TypeError: `this` is `undefined`
{% endcodeblock %}

## 隐含绑定（Implicit Binding）

通过持有调用的环境对象调用，使用那个环境对象。（简单说就是谁调用了函数，函数中的this就指向谁）
代码示例：
{% codeblock lang:JavaScript %}
function foo() {
	console.log( this.a );
}

var obj = {
	a: 2,
	foo: foo
};

obj.foo(); // 2
{% endcodeblock %}

{% codeblock lang:JavaScript %}
// 链式调用

function foo() {
	console.log( this.a );
}

var obj2 = {
	a: 42,
	foo: foo
};

var obj1 = {
	a: 2,
	obj2: obj2
};

obj1.obj2.foo(); // 42
{% endcodeblock %}

## 明确绑定（Explicit Binding）

通过 call 或 apply（或 bind）调用，使用指定的对象。
代码示例：
{% codeblock lang:JavaScript %}
// 就 this 绑定的角度讲，call(..) 和 apply(..) 是完全一样的。
// 它们确实在处理其他参数上的方式不同，但那不是我们当前关心的。

function foo() {
	console.log( this.a );
}

var obj = {
	a: 2
};

foo.call( obj ); // 2
{% endcodeblock %}

{% codeblock lang:JavaScript %}
//  使用ES5中的Function.prototype.bind

function foo(something) {
	console.log( this.a, something );
	return this.a + something;
}

var obj = {
	a: 2
};

var bar = foo.bind( obj );

var b = bar( 3 ); // 2 3
console.log( b ); // 5
{% endcodeblock %}

## new 绑定（new Binding）

通过 new 关键字调用函数, this 指向新构建的对象。

{% codeblock lang:JavaScript %}
function foo(a) {
	this.a = a;
}

var bar = new foo( 2 );
console.log( bar.a ); // 2
{% endcodeblock %}

## 四种规则中优先权

new 绑定 &gt; 明确绑定 &gt; 隐含绑定 &gt; 默认绑定


## 绑定的特例

正如通常的那样，对于“规则”总有一些 例外。

这里不对例外情况做赘述，具体请看原文。

{% blockquote @详情请看 'https://github.com/getify/You-Dont-Know-JS/blob/1ed-zh-CN/this%20%26%20object%20prototypes/ch2.md' 'You-Dont-Know-JS/this & object prototypes/第二章: this 豁然开朗！' %}
{% endblockquote %}