<div id="bg_content" style="position: fixed;
                               top: 0;
                               left: 0;
                               width: 100%;
                               height: 100%;
                               z-index: -1;">
</div>
<script>
var canvasParticle = (function () {
  // base on sunshine940326/canvas-nest(https://github.com/sunshine940326/canvas-nest)
  var canvas, ctx, w, h, circleColor, lineColor
  // 更新页面用requestAnimationFrame替代setTimeout
  window.requestAnimationFrame = window.requestAnimationFrame ||
    window.mozRequestAnimationFrame ||
    window.webkitRequestAnimationFrame ||
    window.msRequestAnimationFrame ||
    function (callback) {
      window.setTimeout(callback, 1000 / 60)
    }
  var circles = []

  var animation = function () { //  圆点移动动画
    var cLen = circles.length
    ctx.clearRect(0, 0, w, h)
    for (var i = 0; i < cLen; i++) {
      circles[i].move()
      circles[i].drawCircle()
      for (var j = i + 1; j < cLen; j++) {
        if (i === j) continue //  自身不用连线
        circles[i].drawLine(circles[j])
      }
    }
    window.requestAnimationFrame(animation)
  }

  /**
   * 初始化
   * @param num
   * @param configuration 配置对象
     */
  var init = function (num, configuration) {
    canvas = document.createElement('canvas')
    ctx = canvas.getContext('2d')
    var config = configuration || {}
    if (config.container) {
      var boundingClientRect = config.container.getBoundingClientRect()
      w = canvas.width = boundingClientRect.width
      h = canvas.height = boundingClientRect.height
    } else {
      config.container = document.getElementsByTagName('body')[0]
      w = canvas.width = document.body.offsetWidth
      h = canvas.height = document.body.offsetHeight
    }
    config.container.append(canvas)
    if (config.circleColor) {
      circleColor = config.circleColor
    } else {
      circleColor = 'rgba(204, 204, 204, 0.3)'
    }
    if (config.lineColor) {
      lineColor = config.lineColor
    } else {
      lineColor = 'rgba(204, 204, 204, 0.3)'
    }
    for (var i = 0; i < num; i++) {
      circles.push(new Circle(Math.random() * w, Math.random() * h))
    }
    animation()
  }

  /**
   * 具有圆属性的构造函数
   * @param x 初始化X坐标
   * @param y 初始化Y坐标
   * @constructor
   */
  function Circle (x, y) {
    this.x = x
    this.y = y
    this.r = Math.random() * 10
    this._mx = Math.random()
    this._my = Math.random()
  }

  Circle.prototype.drawCircle = function () { //  绘制圆
    ctx.beginPath()
    ctx.arc(this.x, this.y, this.r, 0, 2 * Math.PI)
    ctx.fillStyle = circleColor
    ctx.fill()
  }

  Circle.prototype.drawLine = function (otherCircle) { //  画线连接附近其他圆
    var dx = this.x - otherCircle.x
    var dy = this.y - otherCircle.y
    var d = Math.sqrt(dx * dx + dy * dy)
    if (d < 150) {
      ctx.beginPath()
      ctx.moveTo(this.x, this.y)
      ctx.lineTo(otherCircle.x, otherCircle.y)
      ctx.closePath()
      ctx.strokeStyle = lineColor
      ctx.stroke()
    }
  }

  Circle.prototype.move = function () { //  圆点移动
    this._mx = (this.x > 0 && this.x < w) ? this._mx : -this._mx
    this._my = (this.y > 0 && this.y < h) ? this._my : -this._my
    this.x += this._mx
    this.y += this._my
  }

  return {
    init: init
  }
})()
canvasParticle.init(60, {container: document.getElementById('bg_content')})
</script>
