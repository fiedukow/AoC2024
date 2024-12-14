using System;
using System.Text.RegularExpressions;

public static class Constants
{
    public const int WIDTH = 101;
    public const int HEIGHT = 103;
}

class Robot
{
    public int xV { get; set; }
    public int yV { get; set; }

    public int xPos { get; set; }
    public int yPos { get; set; }


    public Robot(Match match) {
        xPos = int.Parse(match.Groups[1].Value);
        yPos = int.Parse(match.Groups[2].Value);
        xV = int.Parse(match.Groups[3].Value);
        yV = int.Parse(match.Groups[4].Value);
    }

    HashSet<(int, int)> priorPos = new HashSet<(int, int)>{};

    public void passTime(int n) {
      // priorPos.Add((xPos, yPos));
      xPos = (xPos + xV * n) % Constants.WIDTH;
      if (xPos < 0) {
        xPos += Constants.WIDTH;
      }
      yPos = (yPos + yV * n) % Constants.HEIGHT;
      if (yPos < 0) {
        yPos += Constants.HEIGHT;
      }
      if (priorPos.Contains((xPos, yPos))) {
        Console.WriteLine("BEEN THERE");
      }
    }

    public int quadrant() {
      if (xPos < Constants.WIDTH / 2 && yPos < Constants.HEIGHT / 2) { return 0; }
      if (xPos > Constants.WIDTH / 2 && yPos < Constants.HEIGHT / 2) { return 1; }
      if (xPos < Constants.WIDTH / 2 && yPos > Constants.HEIGHT / 2) { return 2; }
      if (xPos > Constants.WIDTH / 2 && yPos > Constants.HEIGHT / 2) { return 3; }
      return 4;
    }

    public override string ToString()
    {
        return $"Robot {{ xV = {xV}, yV = {yV}, xPos = {xPos}, yPos = {yPos} }}";
    }
};

class Program
{
    static void Main()
    {
      string text = File.ReadAllText("input.txt");

      string pattern = @"^p=(\d+),(\d+) v=(-?\d+),(-?\d+)$";
      Regex regex = new Regex(pattern, RegexOptions.Multiline);

      List<Robot> robots = new List<Robot>();

      foreach (Match match in regex.Matches(text))
      {
          if (match.Success)
          {
              robots.Add(new Robot(match));
          }
      }

      int[] counts = new int[] { 0, 0, 0, 0, 0 };

      foreach (Robot robot in robots) {
        robot.passTime(100);
        counts[robot.quadrant()] += 1;
      }

      int score = counts[0] * counts[1] * counts[2] * counts[3];

      Console.WriteLine($"Part 1: {score}");

      // 6668 - 100 = 6568
      foreach (Robot robot in robots) {
        robot.passTime(6568);
      }

      int[,] picture = new int[Constants.HEIGHT, Constants.WIDTH];

      foreach (Robot robot in robots) {
        picture[robot.yPos,robot.xPos]++;
      }

      for (int ii = 0; ii < picture.GetLength(0); ii++)
      {
          for (int j = 0; j < picture.GetLength(1); j++)
          {
              Console.Write(picture[ii, j] == 0 ? " " : "*");
          }
          Console.WriteLine();
      }
    }
};
