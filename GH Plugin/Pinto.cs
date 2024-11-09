using Grasshopper.Kernel;
using Rhino.Geometry;
using System.Collections.Generic;
using System;

namespace MoP
{
    public class PintoGraph : GH_Component
    {
        public PintoGraph()
          : base("Pintograph", "Pintograph", "Simulates a pintograph drawing machine", "Category", "Subcategory")
        {
        }

        protected override void RegisterInputParams(GH_InputParamManager pManager)
        {
            pManager.AddNumberParameter("Time", "T", "Time (in seconds)", GH_ParamAccess.item);
            pManager.AddNumberParameter("Distances", "Distances", "List of distances between the centers of the disks", GH_ParamAccess.list); // Combined distances
            pManager.AddNumberParameter("Radii", "Radii", "List of radii of the disks", GH_ParamAccess.list);
            pManager.AddNumberParameter("Speeds", "Speeds", "List of speeds of the disks (in RPS)", GH_ParamAccess.list);
            pManager.AddBooleanParameter("Directions", "Directions", "List of rotation directions of the disks (true for clockwise, false for counterclockwise)", GH_ParamAccess.list);
            pManager.AddNumberParameter("Rod Lengths", "Rod Lengths", "List of rod lengths", GH_ParamAccess.list);

        }

        protected override void RegisterOutputParams(GH_OutputParamManager pManager)
        {
            pManager.AddCurveParameter("Geometry", "G", "Generated pintograph geometry", GH_ParamAccess.list);
            pManager.AddPointParameter("First intersection", "I1", "First rod intersection point", GH_ParamAccess.list);
            pManager.AddPointParameter("Second intersection", "I2", "Second rod intersection point", GH_ParamAccess.list);
            pManager.AddPointParameter("Path", "P", "Generated pintograph path", GH_ParamAccess.list);
        }

        protected override void SolveInstance(IGH_DataAccess DA)
        {

            double t = 0;
            List<double> distances = new List<double>();
            List<double> radii = new List<double>();
            List<double> speeds = new List<double>();
            List<bool> directions = new List<bool>();
            List<double> lengths = new List<double>();

            if (!DA.GetData(0, ref t)) return;
            if (!DA.GetDataList(1, distances)) return;
            if (!DA.GetDataList(2, radii)) return;
            if (!DA.GetDataList(3, speeds)) return;
            if (!DA.GetDataList(4, directions)) return;
            if (!DA.GetDataList(5, lengths)) return;


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

            // Disks centers
            Point3d p1 = new Point3d(0, 0, 0);
            Point3d p2 = new Point3d(d1, 0, 0);
            Point3d p3 = new Point3d(d1 / 2, -d2, 0);

            // Calculate points A and B on the edges of the circles
            Point3d A = new Point3d(p1.X + r1 * Math.Cos(omega1 * t), p1.Y + r1 * Math.Sin(omega1 * t), p1.Z);
            Point3d B = new Point3d(p2.X + r2 * Math.Cos(omega2 * t), p2.Y + r2 * Math.Sin(omega2 * t), p2.Z);
            Point3d H = FindIntersection(A, l1, B, l2, 0);
            Point3d C = H + (l4 / l1) * (H - A);
            Point3d D = H + (l3 / l2) * (H - B);
            Point3d E = FindIntersection(C, l5, D, l6, 1);
            Point3d P = E + (l7 / l5) * (E - C);

            // Create the circles
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

            List<Curve> geometry = new List<Curve>();
            geometry.Add(circle1.ToNurbsCurve());
            geometry.Add(circle2.ToNurbsCurve());
            geometry.Add(circle3.ToNurbsCurve());
            geometry.Add(rod1.ToNurbsCurve());
            geometry.Add(rod2.ToNurbsCurve());
            geometry.Add(rod3.ToNurbsCurve());
            geometry.Add(rod4.ToNurbsCurve());
            geometry.Add(rod5.ToNurbsCurve());
            geometry.Add(rod6.ToNurbsCurve());

            DA.SetDataList(0, geometry);
            DA.SetData(1, H); // First intersection
            DA.SetData(2, E); // Second intersection
            DA.SetData(3, P); // Generated path
        }

        private Point3d FindIntersection(Point3d P1, double L1, Point3d P2, double L2, int direction)
        {
            // Using the law of cosines to find intersection point
            double d = P1.DistanceTo(P2);
            double a = (L1 * L1 - L2 * L2 + d * d) / (2 * d);
            double h = Math.Sqrt(L1 * L1 - a * a);
            Point3d P = P1 + (a / d) * (P2 - P1);
            Vector3d offset = new Vector3d((P2.Y - P1.Y) * (h / d), (P1.X - P2.X) * (h / d), 0);
            Point3d E1 = P + offset;
            Point3d E2 = P - offset;

            if (direction == 0)
                return E1;
            else
                return E2;
        }

        public override Guid ComponentGuid => new Guid("362a53e0-a0d5-4347-9393-bfa44d102ff7");
    }
}
