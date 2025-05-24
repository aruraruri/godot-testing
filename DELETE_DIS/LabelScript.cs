using Godot;
using System;
using System.Runtime.CompilerServices;

public partial class LabelScript : Label
{
    [Export]
    public int Speed { get; set; } = 400; // How fast the player will move (pixels/sec).

    public Vector2 ScreenSize; // Size of the game window.


    public override void _Ready()
    {
        ScreenSize = GetViewportRect().Size;
        
        

    }


    private Tween _tween;
    public override void _Process(double delta)
    {
        var velocity = Vector2.Zero; // The player's movement vector.

        if (_tween != null && _tween.IsRunning())
        _tween.Stop();

        if (Input.IsActionPressed("right"))
        {
            velocity.X += 1;
        }

        if (Input.IsActionPressed("left"))
        {
            velocity.X -= 1;
        }

        if (Input.IsActionPressed("down"))
        {
            velocity.Y += 1;
        }

        if (Input.IsActionPressed("up"))
        {
            velocity.Y -= 1;
        }

        GD.Print(velocity.X, velocity);

        //var label = GetNode<Label>("Label");

        if (velocity.Length() > 0)
    {   
        GD.Print("yes speed");
        _tween = CreateTween();
        velocity = velocity.Normalized() * Speed;
        var currentPos = this.GetPosition();
        _tween.TweenProperty(this, "position", currentPos+velocity, 7.0f);
    }
    else
    {   
        
    }
    }
}
