part of game;

class EyeToggle extends Sprite {
    EyeToggle() {
        scaleX = scaleY = 10;
        x = stage.stageWidth - 20;
        y = stage.stageHeight - 20;
        _update();
        onMouseDown.listen((e) {
            relaxMode = !relaxMode;
            _update();
            updateRelaxMode();
        });

        hitArea = new GlassPlate(4, 2);
        hitArea.pivotX = 2;
        hitArea.pivotY = 1;
        // hitArea.graphics.rect(-1, -1, 2, 2);
        // hitArea.graphics.fillColor(0xAA00FF00);
        addChild(hitArea);
    }

    void _update() {
        graphics.clear();
        graphics.beginPath();
        graphics.moveTo(-1.5, 0);
        graphics.bezierCurveTo(-0.2,  1, 0.2,  1,  1.5, 0);
        graphics.bezierCurveTo( 0.2, -1,-0.2, -1, -1.5, 0);
        graphics.closePath();
        graphics.circle(0, 0, 0.6);
        graphics.strokeColor(0xFFFFFFFF, 0.1);
        if(relaxMode) {
            graphics.fillColor(0xFFFFFFFF);
        }
    }
}
