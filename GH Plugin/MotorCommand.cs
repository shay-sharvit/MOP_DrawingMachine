using System;
using System.Collections.Generic;
using System.IO.Ports;
using Grasshopper.Kernel;
using Rhino.Geometry;

namespace MoP
{
    public class MotorCommand : GH_Component
    {
        public MotorCommand()
          : base("MotorCommand", "MotorCmd", "Sends commands to a motor controller", "Category", "Subcategory")
        {
        }

        protected override void RegisterInputParams(GH_InputParamManager pManager)
        {
            pManager.AddBooleanParameter("SendCommand", "Send", "Send command to the motor", GH_ParamAccess.item);
            pManager.AddIntegerParameter("Direction", "Dir", "Direction of the motor (1 for right, -1 for left)", GH_ParamAccess.item);
            pManager.AddNumberParameter("RoundsPerSecond", "RPS", "Speed of the motor (in rounds per second)", GH_ParamAccess.item);
            pManager.AddTextParameter("COM Port", "Port", "COM port to which the motor controller is connected", GH_ParamAccess.item);
            pManager.AddBooleanParameter("Stop", "Stop", "Stop the motor", GH_ParamAccess.item);
        }

        protected override void RegisterOutputParams(GH_OutputParamManager pManager)
        {
            pManager.AddTextParameter("Response", "Resp", "Response from the motor controller", GH_ParamAccess.item);
        }

        protected override void SolveInstance(IGH_DataAccess DA)
        {
            bool sendCommand = false;
            int direction = 0;
            double roundsPerSecond = 0;
            string comPort = "";
            bool stop = false;

            if (!DA.GetData(0, ref sendCommand)) return;
            if (!DA.GetData(1, ref direction)) return;
            if (!DA.GetData(2, ref roundsPerSecond)) return;
            if (!DA.GetData(3, ref comPort)) return;
            if (!DA.GetData(4, ref stop)) return;

            int stepsPerRevolution = 200;
            int microStepsPerRevolution = stepsPerRevolution * 256;
            int pulseDiv = 1;

            string response = "Command not sent.";

            if (sendCommand)
            {
                int command = direction == 1 ? 1 : 2; // 1 for ROR (Rotate Right), 2 for ROL (Rotate Left)
                int velocity = ConvertRpsToVint(roundsPerSecond, microStepsPerRevolution, pulseDiv);
                byte[] commandPacket = AssembleCommandPacket(1, command, 0, 0, velocity);
                response = SendCommandToTMCM1110(commandPacket, comPort);
            }
            else if (stop)
            {
                int command = 3; // Command to stop the motor
                byte[] commandPacket = AssembleCommandPacket(1, command, 0, 0, 0);
                response = SendCommandToTMCM1110(commandPacket, comPort);
            }

            DA.SetData(0, response);
        }

        private int ConvertRpsToVint(double rps, int stepsPerRevolution, int pulseDiv)
        {
            double pps = rps * stepsPerRevolution;
            int vint = (int)((pps * Math.Pow(2, pulseDiv) * 2048 * 32) / (16 * Math.Pow(10, 6)));
            return vint;
        }

        private byte CalculateChecksum(byte[] command)
        {
            int sum = 0;
            for (int i = 0; i < command.Length - 1; i++)
            {
                sum += command[i];
            }
            return (byte)(sum % 256);
        }

        private byte[] AssembleCommandPacket(int address, int command, int type, int motor, int value)
        {
            byte[] commandPacket = new byte[9];
            commandPacket[0] = (byte)address;
            commandPacket[1] = (byte)command;
            commandPacket[2] = (byte)type;
            commandPacket[3] = (byte)motor;
            commandPacket[4] = (byte)((value >> 24) & 0xFF);
            commandPacket[5] = (byte)((value >> 16) & 0xFF);
            commandPacket[6] = (byte)((value >> 8) & 0xFF);
            commandPacket[7] = (byte)(value & 0xFF);
            commandPacket[8] = CalculateChecksum(commandPacket);
            return commandPacket;
        }

        private string SendCommandToTMCM1110(byte[] commandPacket, string port)
        {
            try
            {
                using (SerialPort serialPort = new SerialPort(port, 9600, Parity.None, 8, StopBits.One))
                {
                    serialPort.Open();
                    serialPort.Write(commandPacket, 0, commandPacket.Length);
                    byte[] response = new byte[9];
                    serialPort.Read(response, 0, response.Length);
                    serialPort.Close();
                    return BitConverter.ToString(response);
                }
            }
            catch (Exception ex)
            {
                return ex.Message;
            }
        }

        public override Guid ComponentGuid => new Guid("fc0909e9-7363-458f-9434-76435a6fc77b");
    }
}
