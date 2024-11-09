using Grasshopper.Kernel;
using Rhino.Geometry;
using System.Collections.Generic;
using System;
using System.Diagnostics;
using Rhino.UI;
using Rhino;
using static Rhino.Runtime.ViewCaptureWriter;

namespace MoP
{
    public class Time_PintoGraph : GH_Component
    {
        private DateTime _start = DateTime.MinValue;
        private bool _isRunning = false;
        private List<Point3d> _pathPoints = new List<Point3d>();
        List<Curve> _geometry = new List<Curve>();
        Point3d _lastH;
        Point3d _lastE;
        Point3d _lastP;


        public Time_PintoGraph()
          : base("Time_PintoGraph", "T_Pintograph", "Simulates a pintograph drawing machine", "Category", "Subcategory")
        {
        }

        protected override void RegisterInputParams(GH_InputParamManager pManager)
        {
            pManager.AddBooleanParameter("Start", "Start", "Start the simulation", GH_ParamAccess.item);
            pManager.AddBooleanParameter("Reset", "Reset", "Reset the simulation", GH_ParamAccess.item);
            pManager.AddNumberParameter("Runtime", "Runtime", "Time the instance should run (in seconds)", GH_ParamAccess.item);
            pManager.AddNumberParameter("Distances", "Distances", "List of distances between the centers of the disks", GH_ParamAccess.list); // Combined distances
            pManager.AddNumberParameter("Radii", "Radii", "List of radii of the disks", GH_ParamAccess.list);
            pManager.AddNumberParameter("Speeds", "Speeds", "List of speeds of the disks (in RPS)", GH_ParamAccess.list);
            pManager.AddBooleanParameter("Directions", "Directions", "List of rotation directions of the disks (true for clockwise, false for counterclockwise)", GH_ParamAccess.list);
            pManager.AddNumberParameter("Rod Lengths", "Rod Lengths", "List of rod lengths", GH_ParamAccess.list);
        }

        protected override void RegisterOutputParams(GH_OutputParamManager pManager)
        {
            pManager.AddCurveParameter("Geometry", "G", "Generated pintograph geometry", GH_ParamAccess.list);
            pManager.AddPointParameter("First Intersection", "I1", "First rod intersection point", GH_ParamAccess.item);
            pManager.AddPointParameter("Second Intersection", "I2", "Second rod intersection point", GH_ParamAccess.item);
            pManager.AddPointParameter("Current Position", "P", "Current position of point P", GH_ParamAccess.item);
            pManager.AddCurveParameter("Path", "Path", "Path of point P during the runtime", GH_ParamAccess.item);
            pManager.AddNumberParameter("Time", "Time", "Current Time", GH_ParamAccess.item);
        }

        protected override void SolveInstance(IGH_DataAccess DA)
        {
            bool start = false;
            bool reset = false;
            double runtime = 0;
            List<double> distances = new List<double>();
            List<double> radii = new List<double>();
            List<double> speeds = new List<double>();
            List<bool> directions = new List<bool>();
            List<double> lengths = new List<double>();

            if (!DA.GetData(0, ref start)) return;
            if (!DA.GetData(1, ref reset)) return;
            if (!DA.GetData(2, ref runtime)) return;
            if (!DA.GetDataList(3, distances)) return;
            if (!DA.GetDataList(4, radii)) return;
            if (!DA.GetDataList(5, speeds)) return;
            if (!DA.GetDataList(6, directions)) return;
            if (!DA.GetDataList(7, lengths)) return;

            if (reset)
            {
                _start = DateTime.Now;
                _isRunning = false;
                 _pathPoints.Clear();
            }

            if (start)
            {
                _isRunning = true;
            }


            double elapsedTime = (DateTime.Now - _start).TotalSeconds;
            double t = elapsedTime;

            if (elapsedTime > runtime)
            {
                _isRunning = false;
                
            }

            if (!_isRunning)
            {
                Polyline last_pathPolyline = new Polyline(_pathPoints);
                Curve last_pathCurve = last_pathPolyline.ToNurbsCurve();
                // Output data
                DA.SetDataList(0, _geometry);
                DA.SetData(1, _lastH); // First intersection
                DA.SetData(2, _lastE); // Second intersection
                DA.SetData(3, _lastP); // Current position of P
                DA.SetData(4, last_pathCurve); // Path of all points P
                DA.SetData(5, 0); // time
                return;
            }


            // Validate list lengths
            if (radii.Count != 3) { AddRuntimeMessage(GH_RuntimeMessageLevel.Error, "Radii list must contain exactly 3 values."); return; }
            if (speeds.Count != 3) { AddRuntimeMessage(GH_RuntimeMessageLevel.Error, "Speeds list must contain exactly 3 values."); return; }
            if (directions.Count != 3) { AddRuntimeMessage(GH_RuntimeMessageLevel.Error, "Directions list must contain exactly 3 values."); return; }
            if (distances.Count != 2) { AddRuntimeMessage(GH_RuntimeMessageLevel.Error, "Distances list must contain exactly 2 values."); return; }
            if (lengths.Count != 7) { AddRuntimeMessage(GH_RuntimeMessageLevel.Error, "Rod Lengths list must contain exactly 7 values."); return; }

           
            // Extract individual values
            double r1 = radii[0], r2 = radii[1], r3 = radii[2];
            double s1 = speeds[0], s2 = speeds[1], s3 = speeds[2];
            bool direction1 = directions[0], direction2 = directions[1], direction3 = directions[2];
            double d1 = distances[0], d2 = distances[1];
            double l1 = lengths[0], l2 = lengths[1], l3 = lengths[2], l4 = lengths[3], l5 = lengths[4], l6 = lengths[5], l7 = lengths[6];

            // Convert speeds from RPS to radians per second
            double omega1 = s1 * 2 * Math.PI * (direction1 ? -1 : 1);
            double omega2 = s2 * 2 * Math.PI * (direction2 ? -1 : 1);
            double omega3 = s3 * 2 * Math.PI * (direction3 ? -1 : 1);

            // Disk centers
            Point3d p1 = new Point3d(0, 0, 0);
            Point3d p2 = new Point3d(d1, 0, 0);
            Point3d p3 = new Point3d(d1 / 2, -d2, 0);

            Point3d A = new Point3d(p1.X + r1 * Math.Cos(omega1 * t), p1.Y + r1 * Math.Sin(omega1 * t), p1.Z);
            Point3d B = new Point3d(p2.X + r2 * Math.Cos(omega2 * t), p2.Y + r2 * Math.Sin(omega2 * t), p2.Z);
            Point3d H = FindIntersection(A, l1, B, l2, 0);
            Point3d C = H + (l4 / l1) * (H - A);
            Point3d D = H + (l3 / l2) * (H - B);
            Point3d E = FindIntersection(C, l5, D, l6, 1);
            Point3d P = E + (l7 / l5) * (E - C);
            
        
            Circle circle1 = new Circle(p1, r1);
            Circle circle2 = new Circle(p2, r2);
            Circle circle3 = new Circle(p3, r3);
            // Create the rods
            Line rod1 = new Line(A, C);
            Line rod2 = new Line(B, D);
            Line rod3 = new Line(H, C);
            Line rod4 = new Line(H, D);
            Line rod5 = new Line(C, P);
            Line rod6 = new Line(D, E);

            List<Curve> geometry = new List<Curve>
            {
                circle1.ToNurbsCurve(),
                circle2.ToNurbsCurve(),
                circle3.ToNurbsCurve(),
                rod1.ToNurbsCurve(),
                rod2.ToNurbsCurve(),
                rod3.ToNurbsCurve(),
                rod4.ToNurbsCurve(),
                rod5.ToNurbsCurve(),
                rod6.ToNurbsCurve()
            };
            _geometry = geometry;
            _lastH = H;
            _lastE = E;
            _lastP = P;

           
            Transform pointRotation = Transform.Rotation(omega3 * t, p3);
            Point3d rotatedP = P;
            rotatedP.Transform(pointRotation);
            _pathPoints.Add(rotatedP);
            Polyline pathPolyline = new Polyline(_pathPoints);
            Curve pathCurve = pathPolyline.ToNurbsCurve();
            Transform canvasRotation = Transform.Rotation(-omega3 * t, p3);
            if (pathCurve != null)
            {
                pathCurve.Transform(canvasRotation);
            }
            // Output data
            DA.SetDataList(0, geometry);
            DA.SetData(1, H); // First intersection
            DA.SetData(2, E); // Second intersection
            DA.SetData(3, P); // Current position of P
            DA.SetData(4, pathCurve); // Path of all points P
            DA.SetData(5, t); // time
        }

       

        private Point3d FindIntersection(Point3d P1, double L1, Point3d P2, double L2, int direction)
        {
            // Using the law of cosines to find intersection point
            double d = P1.DistanceTo(P2);
            // Check for valid triangle
            if (d > L1 + L2 || d < Math.Abs(L1 - L2) || d == 0)
            {
                AddRuntimeMessage(GH_RuntimeMessageLevel.Error, "Invalid rod lengths or positions for intersection.");
                return Point3d.Unset;
            }
            double a = (L1 * L1 - L2 * L2 + d * d) / (2 * d);
            double h = Math.Sqrt(L1 * L1 - a * a);
            Point3d P3 = P1 + a * (P2 - P1) / d;
            double offsetX = h * (P2.Y - P1.Y) / d;
            double offsetY = h * (P2.X - P1.X) / d;
            if (direction == 0)
            {
                return new Point3d(P3.X + offsetX, P3.Y - offsetY, 0);
            }
            else
            {
                return new Point3d(P3.X - offsetX, P3.Y + offsetY, 0);
            }
        }

        protected override System.Drawing.Bitmap Icon => null;
        public override Guid ComponentGuid => new Guid("6b5b5ab7-b10a-4e87-a6ae-b9b5a1f5b91f");
    }
}
