// 把图片等比缩小到 800×480 px 以内（只缩小，不放大）
// 用法：视图 → 宏 → 新建 → 粘贴本文件 → 点“运行”（▶）
// 单位：1 px = 9525 EMU（96 DPI）

(function () {
  var EMU = 9525;
  var MAX_W = 800 * EMU;
  var MAX_H = 480 * EMU;

  // 表格用当前工作表；文档/幻灯片用文档
  var sheet = Api.GetActiveSheet && Api.GetActiveSheet();
  var images = (sheet && sheet.GetAllImages)
    ? sheet.GetAllImages()
    : Api.GetDocument().GetAllImages();

  for (var i = 0; i < images.length; i++) {
    var img = images[i];
    var w = img.GetWidth();
    var h = img.GetHeight();
    if (!w || !h) continue;

    var s = Math.min(1, MAX_W / w, MAX_H / h);
    if (s < 1) {
      img.SetSize(Math.round(w * s), Math.round(h * s));
    }
  }
})();
