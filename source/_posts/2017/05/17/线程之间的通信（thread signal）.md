---
title: 线程之间的通信（thread signal）
date: 2017-05-17 23:41:22
tags:
  - java
  - 多线程
  - 线程通信
---
线程通信的目的是为了能够让线程之间相互发送信号。另外，线程通信还能够使得线程等待其它线程的信号，比如，线程B可以等待线程A的信号，这个信号可以是线程A已经处理完成的信号。

## 通过共享对象通信

有一个简单的实现线程之间通信的方式，就是在共享对象的变量中设置信号值。比如线程A在一个同步块中设置一个成员变量hasDataToProcess值为true，而线程B同样在一个同步块中读取这个成员变量。下面例子演示了一个持有信号值的对象，并提供了设置信号值和获取信号值的同步方法：

{% codeblock lang:java %}
public class MySignal {
    private boolean hasDataToProcess;

    public synchronized void setHasDataToProcess(boolean hasData){
        this.hasDataToProcess=hasData;
    }
    public synchronized boolean hasDataToProcess(){
        return this.hasDataToProcess;
    }

}
{% endcodeblock %}
<!-- more -->

ThreadB计算完成会在共享对象中设置信号值：

{% codeblock lang:java %}
public class ThreadB extends Thread{
    int count;
    MySignal mySignal;
    public ThreadB(MySignal mySignal){
        this.mySignal=mySignal;
    }
    @Override
    public void run(){
        for(int i=0;i<100;i++){
            count=count+1;
        }
        try {
            Thread.sleep(500);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        mySignal.setHasDataToProcess(true);
    }
}
{% endcodeblock %}

ThreadA在循环中一直检测共享对象的信号值，等待ThreadB计算完成的信号：

{% codeblock lang:java %}
public class ThreadA extends Thread{
    MySignal mySignal;
    ThreadB threadB;
    public ThreadA(MySignal mySignal, ThreadB threadB){
        this.mySignal=mySignal;
        this.threadB=threadB;
    }
    @Override
    public void run(){
        while (true){
            if(mySignal.hasDataToProcess()){
                System.out.println("线程B计算结果为:"+threadB.count);
                break;
            }
        }
    }
    public static void main(String[] args) {
        MySignal mySignal=new MySignal();
        ThreadB threadB=new ThreadB(mySignal);
        ThreadA threadA=new ThreadA(mySignal,threadB);
        threadB.start();
        threadA.start();
    }
}
{% endcodeblock %}

很明显，采用共享对象方式通信的线程A和线程B必须持有同一个MySignal对象的引用，这样它们才能彼此检测到对方设置的信号。当然，信号也可存储在共享内存buffer中，它和实例是分开的。

## 线程的忙等

从上面例子中可以看出，线程A一直在等待数据就绪，或者说线程A一直在等待线程B设置hasDataToProcess的信号值为true：

{% codeblock lang:java %}
public void run(){
    while (true){
        if(mySignal.hasDataToProcess()){
            System.out.println("线程B计算结果为:"+threadB.count);
            break;
        }
    }
}
{% endcodeblock %}

为什么说是忙等呢？因为上面代码一直在执行循环，直到hasDataToProcess被设置为true。

忙等意味着线程还处于运行状态，一直在消耗CPU资源，所以，忙等不是一种很好的现象。那么能不能让线程在等待信号时释放CPU资源进入阻塞状态呢？其实java.lang.Object提供的wait()、notify()、notifyAll()方法就可以解决忙等问题。

## wait()、notify()、notifyAll()

Java提供了一种内联机制可以让线程在等待信号时进入非运行状态。当一个线程调用任何对象上的wait()方法时便会进入非运行状态，直到另一个线程调用同一个对象上的notify()或notifyAll()方法。

为了能够调用一个对象的wait()、notify()方法，调用线程必须先获得这个对象的锁。因为线程只有在同步块中才会占用对象的锁，所以线程必须在同步块中调用wait()、notify()方法。

我们把上面通过共享对象通信的例子改成调用对象wait()、notify()方法来实现：

首先我们先构造一个任意对象，我们又把它称作监控对象：

{% codeblock lang:java %}
public class MonitorObject {

}
{% endcodeblock %}

ThreadD负责计算，在计算完成时唤醒被阻塞的ThreadC:

{% codeblock lang:java %}
public class ThreadD extends Thread{
    int count;
    MonitorObject mySignal;
    public ThreadD(MonitorObject mySignal){
        this.mySignal=mySignal;
    }
    @Override
    public void run(){
        for(int i=0;i<100;i++){
            count=count+1;
        }
        try {
            Thread.sleep(500);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        synchronized (mySignal){
            mySignal.notify();//计算完成调用对象的notify()方法，唤醒因调用这个对象wait()方法而挂起的线程
        }
    }
}
{% endcodeblock %}

ThreadC等待ThreadD的唤醒：

{% codeblock lang:java %}
public class ThreadC extends Thread{
    MonitorObject mySignal;
    ThreadD threadD;
    public ThreadC(MonitorObject mySignal, ThreadD threadD){
        this.mySignal=mySignal;
        this.threadD=threadD;
    }
    @Override
    public void run(){
       synchronized (mySignal){
           try {
               mySignal.wait();
           } catch (InterruptedException e) {
               e.printStackTrace();
           }
           System.out.println("线程B计算结果为:"+threadD.count);
       }
    }
    public static void main(String[] args) {
        MonitorObject mySignal=new MonitorObject();
        ThreadD threadD=new ThreadD(mySignal);
        ThreadC threadC=new ThreadC(mySignal,threadD);
        threadC.start();
        threadD.start();
    }

}
{% endcodeblock %}

在这个例子中，线程C因调用了监控对象的wait()方法而挂起，线程D通过调用监控对象的notify()方法唤醒挂起的线程C。我们还可以看到，两个线程都是在同步块中调用的wait()和notify()方法。如果一个线程在没有获得对象锁的前提下调用了这个对象的wait()或notify()方法，方法调用时将会抛出 IllegalMonitorStateException异常。

注意，当一个线程调用一个对象的notify()方法，则会唤醒正在等待这个对象所有线程中的一个线程（唤醒的线程是随机的），当线程调用的是对象的notifyAll()方法，则会唤醒所有等待这个对象的线程（唤醒的所有线程中哪一个会执行也是不确定的）。

这里还有一个问题，既然调用对象wait()方法的线程需要获得这个对象的锁，那么这会不会阻塞其它线程调用这个对象的notify()方法呢？答案是不会阻塞，当一个线程调用监控对象的wait()方法时，它便会释放掉这个监控对象锁，以便让其它线程能够调用这个对象的notify()方法或者wait()方法。

另外，当一个线程被唤醒时不会立刻退出wait()方法，只有当调用notify()的线程退出它的同步块为止。也就是说，被唤醒的线程只有重新获得监控对象锁时才会退出wait()方法，因为wait()方法在同步块中，它的执行需要再次获得对象锁。所以，当通过notifyAll()方法唤醒被阻塞的线程时，一次只能有一个线程会退出wait()方法，同样是因为每个线程都需要先获得监控对象锁才能执行同步块中的wait()方法退出。

{% blockquote @原文地址 https://blog.csdn.net/suifeng3051/article/details/51863010 %}
{% endblockquote %}