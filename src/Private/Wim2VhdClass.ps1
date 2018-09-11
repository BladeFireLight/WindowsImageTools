$code      = @"
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Security;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Xml.Linq;
using System.Xml.XPath;
using Microsoft.Win32.SafeHandles;

namespace WIM2VHD {

    /// <summary>
    /// P/Invoke methods and associated enums, flags, and structs.
    /// </summary>
    public class
    NativeMethods {

        #region Delegates and Callbacks
        #region WIMGAPI

        ///<summary>
        ///User-defined function used with the RegisterMessageCallback or UnregisterMessageCallback function.
        ///</summary>
        ///<param name="MessageId">Specifies the message being sent.</param>
        ///<param name="wParam">Specifies additional message information. The contents of this parameter depend on the value of the
        ///MessageId parameter.</param>
        ///<param name="lParam">Specifies additional message information. The contents of this parameter depend on the value of the
        ///MessageId parameter.</param>
        ///<param name="UserData">Specifies the user-defined value passed to RegisterCallback.</param>
        ///<returns>
        ///To indicate success and to enable other subscribers to process the message return WIM_MSG_SUCCESS.
        ///To prevent other subscribers from receiving the message, return WIM_MSG_DONE.
        ///To cancel an image apply or capture, return WIM_MSG_ABORT_IMAGE when handling the WIM_MSG_PROCESS message.
        ///</returns>
        public delegate uint
        WimMessageCallback(
            uint   MessageId,
            IntPtr wParam,
            IntPtr lParam,
            IntPtr UserData
        );

        public static void
        RegisterMessageCallback(
            WimFileHandle hWim,
            WimMessageCallback callback) {

            uint _callback = NativeMethods.WimRegisterMessageCallback(hWim, callback, IntPtr.Zero);
            int rc = Marshal.GetLastWin32Error();
            if (0 != rc) {
                // Throw an exception if something bad happened on the Win32 end.
                throw
                    new InvalidOperationException(
                        string.Format(
                            CultureInfo.CurrentCulture,
                            "Unable to register message callback."
                ));
            }
        }

        public static void 
        UnregisterMessageCallback(
            WimFileHandle hWim,
            WimMessageCallback registeredCallback) {

            bool status = NativeMethods.WimUnregisterMessageCallback(hWim, registeredCallback);
            int rc = Marshal.GetLastWin32Error();
            if (!status) {
                throw
                    new InvalidOperationException(
                        string.Format(
                            CultureInfo.CurrentCulture,
                            "Unable to unregister message callback."
                ));
            }
        }

        #endregion WIMGAPI
        #endregion Delegates and Callbacks

        #region Constants

        #region VDiskInterop

        /// <summary>
        /// The default depth in a VHD parent chain that this library will search through.
        /// If you want to go more than one disk deep into the parent chain, provide a different value.
        /// </summary>
        public   const uint  OPEN_VIRTUAL_DISK_RW_DEFAULT_DEPTH   = 0x00000001;

        public   const uint  DEFAULT_BLOCK_SIZE                   = 0x00080000;
        public   const uint  DISK_SECTOR_SIZE                     = 0x00000200;

        internal const uint  ERROR_VIRTDISK_NOT_VIRTUAL_DISK      = 0xC03A0015;
        internal const uint  ERROR_NOT_FOUND                      = 0x00000490;
        internal const uint  ERROR_IO_PENDING                     = 0x000003E5;
        internal const uint  ERROR_INSUFFICIENT_BUFFER            = 0x0000007A;
        internal const uint  ERROR_ERROR_DEV_NOT_EXIST            = 0x00000037;
        internal const uint  ERROR_BAD_COMMAND                    = 0x00000016;
        internal const uint  ERROR_SUCCESS                        = 0x00000000;

        public   const uint  GENERIC_READ                         = 0x80000000;
        public   const uint  GENERIC_WRITE                        = 0x40000000;
        public   const short FILE_ATTRIBUTE_NORMAL                = 0x00000080;
        public   const uint  CREATE_NEW                           = 0x00000001;
        public   const uint  CREATE_ALWAYS                        = 0x00000002;
        public   const uint  OPEN_EXISTING                        = 0x00000003;
        public   const short INVALID_HANDLE_VALUE                 = -1;

        internal static Guid VirtualStorageTypeVendorUnknown      = new Guid("00000000-0000-0000-0000-000000000000");
        internal static Guid VirtualStorageTypeVendorMicrosoft    = new Guid("EC984AEC-A0F9-47e9-901F-71415A66345B");

        #endregion VDiskInterop

        #region WIMGAPI

        public   const uint  WIM_FLAG_VERIFY                      = 0x00000002;
        public   const uint  WIM_FLAG_INDEX                       = 0x00000004;

        public   const uint  WM_APP                               = 0x00008000;

        #endregion WIMGAPI

        #endregion Constants

        #region Enums and Flags

        #region VDiskInterop

        /// <summary>
        /// Indicates the version of the virtual disk to create.
        /// </summary>
        public enum CreateVirtualDiskVersion : int {
            VersionUnspecified         = 0x00000000,
            Version1                   = 0x00000001,
            Version2                   = 0x00000002
        }

        public enum OpenVirtualDiskVersion : int {
            VersionUnspecified         = 0x00000000,
            Version1                   = 0x00000001,
            Version2                   = 0x00000002
        }

        /// <summary>
        /// Contains the version of the virtual hard disk (VHD) ATTACH_VIRTUAL_DISK_PARAMETERS structure to use in calls to VHD functions.
        /// </summary>
        public enum AttachVirtualDiskVersion : int {
            VersionUnspecified         = 0x00000000,
            Version1                   = 0x00000001,
            Version2                   = 0x00000002
        }

        public enum CompactVirtualDiskVersion : int {
            VersionUnspecified         = 0x00000000,
            Version1                   = 0x00000001
        }

        /// <summary>
        /// Contains the type and provider (vendor) of the virtual storage device.
        /// </summary>
        public enum VirtualStorageDeviceType : int {
            /// <summary>
            /// The storage type is unknown or not valid.
            /// </summary>
            Unknown                    = 0x00000000,
            /// <summary>
            /// For internal use only.  This type is not supported.
            /// </summary>
            ISO                        = 0x00000001,
            /// <summary>
            /// Virtual Hard Disk device type.
            /// </summary>
            VHD                        = 0x00000002,
            /// <summary>
            /// Virtual Hard Disk v2 device type.
            /// </summary>
            VHDX                       = 0x00000003
        }

        /// <summary>
        /// Contains virtual hard disk (VHD) open request flags.
        /// </summary>
        [Flags]
        public enum OpenVirtualDiskFlags {
            /// <summary>
            /// No flags. Use system defaults.
            /// </summary>
            None                       = 0x00000000,
            /// <summary>
            /// Open the VHD file (backing store) without opening any differencing-chain parents. Used to correct broken parent links.
            /// </summary>
            NoParents                  = 0x00000001,
            /// <summary>
            /// Reserved.
            /// </summary>
            BlankFile                  = 0x00000002,
            /// <summary>
            /// Reserved.
            /// </summary>
            BootDrive                  = 0x00000004,
        }

        /// <summary>
        /// Contains the bit mask for specifying access rights to a virtual hard disk (VHD).
        /// </summary>
        [Flags]
        public enum VirtualDiskAccessMask {
            /// <summary>
            /// Only Version2 of OpenVirtualDisk API accepts this parameter
            /// </summary>
            None                       = 0x00000000,
            /// <summary>
            /// Open the virtual disk for read-only attach access. The caller must have READ access to the virtual disk image file.
            /// </summary>
            /// <remarks>
            /// If used in a request to open a virtual disk that is already open, the other handles must be limited to either
            /// VIRTUAL_DISK_ACCESS_DETACH or VIRTUAL_DISK_ACCESS_GET_INFO access, otherwise the open request with this flag will fail.
            /// </remarks>
            AttachReadOnly             = 0x00010000,
            /// <summary>
            /// Open the virtual disk for read-write attaching access. The caller must have (READ | WRITE) access to the virtual disk image file.
            /// </summary>
            /// <remarks>
            /// If used in a request to open a virtual disk that is already open, the other handles must be limited to either
            /// VIRTUAL_DISK_ACCESS_DETACH or VIRTUAL_DISK_ACCESS_GET_INFO access, otherwise the open request with this flag will fail.
            /// If the virtual disk is part of a differencing chain, the disk for this request cannot be less than the readWriteDepth specified
            /// during the prior open request for that differencing chain.
            /// </remarks>
            AttachReadWrite            = 0x00020000,
            /// <summary>
            /// Open the virtual disk to allow detaching of an attached virtual disk. The caller must have
            /// (FILE_READ_ATTRIBUTES | FILE_READ_DATA) access to the virtual disk image file.
            /// </summary>
            Detach                     = 0x00040000,
            /// <summary>
            /// Information retrieval access to the virtual disk. The caller must have READ access to the virtual disk image file.
            /// </summary>
            GetInfo                    = 0x00080000,
            /// <summary>
            /// Virtual disk creation access.
            /// </summary>
            Create                     = 0x00100000,
            /// <summary>
            /// Open the virtual disk to perform offline meta-operations. The caller must have (READ | WRITE) access to the virtual
            /// disk image file, up to readWriteDepth if working with a differencing chain.
            /// </summary>
            /// <remarks>
            /// If the virtual disk is part of a differencing chain, the backing store (host volume) is opened in RW exclusive mode up to readWriteDepth.
            /// </remarks>
            MetaOperations             = 0x00200000,
            /// <summary>
            /// Reserved.
            /// </summary>
            Read                       = 0x000D0000,
            /// <summary>
            /// Allows unrestricted access to the virtual disk. The caller must have unrestricted access rights to the virtual disk image file.
            /// </summary>
            All                        = 0x003F0000,
            /// <summary>
            /// Reserved.
            /// </summary>
            Writable                   = 0x00320000
        }

        /// <summary>
        /// Contains virtual hard disk (VHD) creation flags.
        /// </summary>
        [Flags]
        public enum CreateVirtualDiskFlags {
            /// <summary>
            /// Contains virtual hard disk (VHD) creation flags.
            /// </summary>
            None                       = 0x00000000,
            /// <summary>
            /// Pre-allocate all physical space necessary for the size of the virtual disk.
            /// </summary>
            /// <remarks>
            /// The CREATE_VIRTUAL_DISK_FLAG_FULL_PHYSICAL_ALLOCATION flag is used for the creation of a fixed VHD.
            /// </remarks>
            FullPhysicalAllocation     = 0x00000001
        }

        /// <summary>
        /// Contains virtual disk attach request flags.
        /// </summary>
        [Flags]
        public enum AttachVirtualDiskFlags {
            /// <summary>
            /// No flags. Use system defaults.
            /// </summary>
            None                       = 0x00000000,
            /// <summary>
            /// Attach the virtual disk as read-only.
            /// </summary>
            ReadOnly                   = 0x00000001,
            /// <summary>
            /// No drive letters are assigned to the disk's volumes.
            /// </summary>
            /// <remarks>Oddly enough, this doesn't apply to NTFS mount points.</remarks>
            NoDriveLetter              = 0x00000002,
            /// <summary>
            /// Will decouple the virtual disk lifetime from that of the VirtualDiskHandle.
            /// The virtual disk will be attached until the Detach() function is called, even if all open handles to the virtual disk are closed.
            /// </summary>
            PermanentLifetime          = 0x00000004,
            /// <summary>
            /// Reserved.
            /// </summary>
            NoLocalHost                = 0x00000008
        }

        [Flags]
        public enum DetachVirtualDiskFlag {
            None                       = 0x00000000
        }

        [Flags]
        public enum CompactVirtualDiskFlags {
            None                       = 0x00000000,
            NoZeroScan                 = 0x00000001,
            NoBlockMoves               = 0x00000002
        }

        #endregion VDiskInterop

        #region WIMGAPI

        [FlagsAttribute]
        internal enum 
        WimCreateFileDesiredAccess 
            : uint {
            WimQuery                   = 0x00000000,
            WimGenericRead             = 0x80000000
        }

        /// <summary>
        /// Specifies how the file is to be treated and what features are to be used.
        /// </summary>
        [FlagsAttribute]
        internal enum
        WimApplyFlags
            : uint {
            /// <summary>
            /// No flags.
            /// </summary>
            WimApplyFlagsNone          = 0x00000000,
            /// <summary>
            /// Reserved.
            /// </summary>
            WimApplyFlagsReserved      = 0x00000001,
            /// <summary>
            /// Verifies that files match original data.
            /// </summary>
            WimApplyFlagsVerify        = 0x00000002,
            /// <summary>
            /// Specifies that the image is to be sequentially read for caching or performance purposes.
            /// </summary>
            WimApplyFlagsIndex         = 0x00000004,
            /// <summary>
            /// Applies the image without physically creating directories or files. Useful for obtaining a list of files and directories in the image.
            /// </summary>
            WimApplyFlagsNoApply       = 0x00000008,
            /// <summary>
            /// Disables restoring security information for directories.
            /// </summary>
            WimApplyFlagsNoDirAcl      = 0x00000010,
            /// <summary>
            /// Disables restoring security information for files
            /// </summary>
            WimApplyFlagsNoFileAcl     = 0x00000020,
            /// <summary>
            /// The .wim file is opened in a mode that enables simultaneous reading and writing.
            /// </summary>
            WimApplyFlagsShareWrite    = 0x00000040,
            /// <summary>
            /// Sends a WIM_MSG_FILEINFO message during the apply operation.
            /// </summary>
            WimApplyFlagsFileInfo      = 0x00000080,
            /// <summary>
            /// Disables automatic path fixups for junctions and symbolic links.
            /// </summary>
            WimApplyFlagsNoRpFix       = 0x00000100,
            /// <summary>
            /// Returns a handle that cannot commit changes, regardless of the access level requested at mount time.
            /// </summary>
            WimApplyFlagsMountReadOnly = 0x00000200,
            /// <summary>
            /// Reserved.
            /// </summary>
            WimApplyFlagsMountFast     = 0x00000400,
            /// <summary>
            /// Reserved.
            /// </summary>
            WimApplyFlagsMountLegacy   = 0x00000800
        }

        public enum WimMessage : uint {
            WIM_MSG                    = WM_APP + 0x1476,                
            WIM_MSG_TEXT,
            ///<summary>
            ///Indicates an update in the progress of an image application.
            ///</summary>
            WIM_MSG_PROGRESS,
            ///<summary>
            ///Enables the caller to prevent a file or a directory from being captured or applied.
            ///</summary>
            WIM_MSG_PROCESS,
            ///<summary>
            ///Indicates that volume information is being gathered during an image capture.
            ///</summary>
            WIM_MSG_SCANNING,
            ///<summary>
            ///Indicates the number of files that will be captured or applied.
            ///</summary>
            WIM_MSG_SETRANGE,
            ///<summary>
            ///Indicates the number of files that have been captured or applied.
            ///</summary>
            WIM_MSG_SETPOS,
            ///<summary>
            ///Indicates that a file has been either captured or applied.
            ///</summary>
            WIM_MSG_STEPIT,
            ///<summary>
            ///Enables the caller to prevent a file resource from being compressed during a capture.
            ///</summary>
            WIM_MSG_COMPRESS,
            ///<summary>
            ///Alerts the caller that an error has occurred while capturing or applying an image.
            ///</summary>
            WIM_MSG_ERROR,
            ///<summary>
            ///Enables the caller to align a file resource on a particular alignment boundary.
            ///</summary>
            WIM_MSG_ALIGNMENT,
            WIM_MSG_RETRY,
            ///<summary>
            ///Enables the caller to align a file resource on a particular alignment boundary.
            ///</summary>
            WIM_MSG_SPLIT,
            WIM_MSG_SUCCESS            = 0x00000000,                
            WIM_MSG_ABORT_IMAGE        = 0xFFFFFFFF
        }

        internal enum 
        WimCreationDisposition 
            : uint {
            WimOpenExisting            = 0x00000003,
        }

        internal enum 
        WimActionFlags 
            : uint {
            WimIgnored                 = 0x00000000
        }

        internal enum 
        WimCompressionType 
            : uint {
            WimIgnored                 = 0x00000000
        }

        internal enum 
        WimCreationResult 
            : uint {
            WimCreatedNew              = 0x00000000,
            WimOpenedExisting          = 0x00000001
        }

        #endregion WIMGAPI

        #endregion Enums and Flags

        #region Structs

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        public struct CreateVirtualDiskParameters {
            /// <summary>
            /// A CREATE_VIRTUAL_DISK_VERSION enumeration that specifies the version of the CREATE_VIRTUAL_DISK_PARAMETERS structure being passed to or from the virtual hard disk (VHD) functions.
            /// </summary>
            public CreateVirtualDiskVersion Version;

            /// <summary>
            /// Unique identifier to assign to the virtual disk object. If this member is set to zero, a unique identifier is created by the system.
            /// </summary>
            public Guid UniqueId;

            /// <summary>
            /// The maximum virtual size of the virtual disk object. Must be a multiple of 512.
            /// If a ParentPath is specified, this value must be zero.
            /// If a SourcePath is specified, this value can be zero to specify the size of the source VHD to be used, otherwise the size specified must be greater than or equal to the size of the source disk.
            /// </summary>
            public ulong MaximumSize;

            /// <summary>
            /// Internal size of the virtual disk object blocks.
            /// The following are predefined block sizes and their behaviors. For a fixed VHD type, this parameter must be zero.
            /// </summary>
            public uint BlockSizeInBytes;

            /// <summary>
            /// Internal size of the virtual disk object sectors. Must be set to 512.
            /// </summary>
            public uint SectorSizeInBytes;

            /// <summary>
            /// Optional path to a parent virtual disk object. Associates the new virtual disk with an existing virtual disk.
            /// If this parameter is not NULL, SourcePath must be NULL.
            /// </summary>
            public string ParentPath;

            /// <summary>
            /// Optional path to pre-populate the new virtual disk object with block data from an existing disk. This path may refer to a VHD or a physical disk.
            /// If this parameter is not NULL, ParentPath must be NULL.
            /// </summary>
            public string SourcePath;

            /// <summary>
            /// Flags for opening the VHD
            /// </summary>
            public OpenVirtualDiskFlags OpenFlags;

            /// <summary>
            /// GetInfoOnly flag for V2 handles
            /// </summary>
            public bool GetInfoOnly;

            /// <summary>
            /// Virtual Storage Type of the parent disk
            /// </summary>
            public VirtualStorageType ParentVirtualStorageType;

            /// <summary>
            /// Virtual Storage Type of the source disk
            /// </summary>
            public VirtualStorageType SourceVirtualStorageType;

            /// <summary>
            /// A GUID to use for fallback resiliency over SMB.
            /// </summary>
            public Guid ResiliencyGuid;
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        public struct VirtualStorageType {
            public VirtualStorageDeviceType DeviceId;
            public Guid VendorId;
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        public struct SecurityDescriptor {
            public byte revision;
            public byte size;
            public short control;
            public IntPtr owner;
            public IntPtr group;
            public IntPtr sacl;
            public IntPtr dacl;
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        public struct
        OpenVirtualDiskParameters {
            public OpenVirtualDiskVersion Version;
            public bool GetInfoOnly;
            public Guid ResiliencyGuid;
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        public struct VirtualDiskProgress {
            public int OperationStatus;
            public ulong CurrentValue;
            public ulong CompletionValue;
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        public struct AttachVirtualDiskParameters {
            public AttachVirtualDiskVersion Version;
            public int Reserved;
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        public struct CompactVirtualDiskParameters {
            public CompactVirtualDiskVersion Version;
            public uint Reserved;
        }

        #endregion Structs

        #region VirtDisk.DLL P/Invoke

        [DllImport("virtdisk.dll", CharSet = CharSet.Unicode)]
        public static extern uint
        CreateVirtualDisk(
            [In, Out] ref VirtualStorageType VirtualStorageType,
            [In]          string Path,
            [In]          VirtualDiskAccessMask VirtualDiskAccessMask,
            [In, Out] ref SecurityDescriptor SecurityDescriptor,
            [In]          CreateVirtualDiskFlags Flags,
            [In]          uint ProviderSpecificFlags,
            [In, Out] ref CreateVirtualDiskParameters Parameters,
            [In]          IntPtr Overlapped,
            [Out]     out SafeFileHandle Handle);

        [DllImport("virtdisk.dll", CharSet = CharSet.Unicode)]
        internal static extern uint
        OpenVirtualDisk(
            [In, Out] ref VirtualStorageType VirtualStorageType,
            [In]          string Path,
            [In]          VirtualDiskAccessMask VirtualDiskAccessMask,
            [In]          OpenVirtualDiskFlags Flags,
            [In, Out] ref OpenVirtualDiskParameters Parameters,
            [Out]     out SafeFileHandle Handle);

        /// <summary>
        /// GetVirtualDiskOperationProgress API allows getting progress info for the async virtual disk operations (ie. Online Mirror)
        /// </summary>
        /// <param name="VirtualDiskHandle"></param>
        /// <param name="Overlapped"></param>
        /// <param name="Progress"></param>
        /// <returns></returns>
        [DllImport("virtdisk.dll", CharSet = CharSet.Unicode)]
        internal static extern uint
        GetVirtualDiskOperationProgress(
            [In]          SafeFileHandle VirtualDiskHandle,
            [In]          IntPtr Overlapped,
            [In, Out] ref VirtualDiskProgress Progress);

        [DllImport("virtdisk.dll", CharSet = CharSet.Unicode)]
        public static extern uint
        AttachVirtualDisk(
            [In]          SafeFileHandle VirtualDiskHandle,
            [In, Out] ref SecurityDescriptor SecurityDescriptor,
            [In]          AttachVirtualDiskFlags Flags,
            [In]          uint ProviderSpecificFlags,
            [In, Out] ref AttachVirtualDiskParameters Parameters,
            [In]          IntPtr Overlapped);

        [DllImport("virtdisk.dll", CharSet = CharSet.Unicode)]
        public static extern uint
        DetachVirtualDisk(
            [In]          SafeFileHandle VirtualDiskHandle,
            [In]          NativeMethods.DetachVirtualDiskFlag Flags,
            [In]          uint ProviderSpecificFlags);

        [DllImport("virtdisk.dll", CharSet = CharSet.Unicode)]
        public static extern uint
        CompactVirtualDisk(
            [In]          SafeFileHandle VirtualDiskHandle,
            [In]          CompactVirtualDiskFlags Flags,
            [In, Out] ref CompactVirtualDiskParameters Parameters,
            [In]          IntPtr Overlapped);

        [DllImport("virtdisk.dll", CharSet = CharSet.Unicode)]
        public static extern uint
        GetVirtualDiskPhysicalPath(
            [In]          SafeFileHandle VirtualDiskHandle,
            [In, Out] ref uint DiskPathSizeInBytes,
            [Out]         StringBuilder DiskPath);

        #endregion VirtDisk.DLL P/Invoke

        #region Win32 P/Invoke

        [DllImport("advapi32", SetLastError = true)]
        public static extern bool InitializeSecurityDescriptor(
            [Out]     out SecurityDescriptor pSecurityDescriptor,
            [In]          uint dwRevision);

        /// <summary>
        /// CreateEvent API is used while calling async Online Mirror API
        /// </summary>
        /// <param name="lpEventAttributes"></param>
        /// <param name="bManualReset"></param>
        /// <param name="bInitialState"></param>
        /// <param name="lpName"></param>
        /// <returns></returns>
        [DllImport("kernel32.dll", CharSet = CharSet.Unicode)]
        internal static extern IntPtr
        CreateEvent(
            [In, Optional]  IntPtr lpEventAttributes,
            [In]            bool bManualReset,
            [In]            bool bInitialState,
            [In, Optional]  string lpName);

        #endregion Win32 P/Invoke

        #region WIMGAPI P/Invoke

        #region SafeHandle wrappers for WimFileHandle and WimImageHandle

        public sealed class WimFileHandle : SafeHandle {

            public WimFileHandle(
                string wimPath)
                : base(IntPtr.Zero, true) {

                if (String.IsNullOrEmpty(wimPath)) {
                    throw new ArgumentNullException("wimPath");
                }

                if (!File.Exists(Path.GetFullPath(wimPath))) {
                    throw new FileNotFoundException((new FileNotFoundException()).Message, wimPath);
                }

                NativeMethods.WimCreationResult creationResult;

                this.handle = NativeMethods.WimCreateFile(
                    wimPath,
                    NativeMethods.WimCreateFileDesiredAccess.WimGenericRead,
                    NativeMethods.WimCreationDisposition.WimOpenExisting,
                    NativeMethods.WimActionFlags.WimIgnored,
                    NativeMethods.WimCompressionType.WimIgnored,
                    out creationResult
                );

                // Check results.
                if (creationResult != NativeMethods.WimCreationResult.WimOpenedExisting) {
                    throw new Win32Exception();
                }

                if (this.handle == IntPtr.Zero) {
                    throw new Win32Exception();
                }

                // Set the temporary path.
                NativeMethods.WimSetTemporaryPath(
                    this,
                    Environment.ExpandEnvironmentVariables("%TEMP%")
                );
            }

            protected override bool ReleaseHandle() {
                return NativeMethods.WimCloseHandle(this.handle);
            }

            public override bool IsInvalid {
                get { return this.handle == IntPtr.Zero; }
            }
        }

        public sealed class WimImageHandle : SafeHandle {
            public WimImageHandle(
                WimFile Container,
                uint ImageIndex)
                : base(IntPtr.Zero, true) {

                if (null == Container) {
                    throw new ArgumentNullException("Container");
                }

                if ((Container.Handle.IsClosed) || (Container.Handle.IsInvalid)) {
                    throw new ArgumentNullException("The handle to the WIM file has already been closed, or is invalid.", "Container");
                }

                if (ImageIndex > Container.ImageCount) {
                    throw new ArgumentOutOfRangeException("ImageIndex", "The index does not exist in the specified WIM file.");
                }

                this.handle = NativeMethods.WimLoadImage(
                    Container.Handle.DangerousGetHandle(),
                    ImageIndex);
            }

            protected override bool ReleaseHandle() {
                return NativeMethods.WimCloseHandle(this.handle);
            }

            public override bool IsInvalid {
                get { return this.handle == IntPtr.Zero; }
            }
        }

        #endregion SafeHandle wrappers for WimFileHandle and WimImageHandle

        [DllImport("Wimgapi.dll", CharSet = CharSet.Unicode, SetLastError = true, EntryPoint = "WIMCreateFile")]
        internal static extern IntPtr
        WimCreateFile(
            [In, MarshalAs(UnmanagedType.LPWStr)] string WimPath,
            [In]    WimCreateFileDesiredAccess DesiredAccess,
            [In]    WimCreationDisposition CreationDisposition,
            [In]    WimActionFlags FlagsAndAttributes,
            [In]    WimCompressionType CompressionType,
            [Out, Optional] out WimCreationResult CreationResult
        );

        [DllImport("Wimgapi.dll", CharSet = CharSet.Unicode, SetLastError = true, EntryPoint = "WIMCloseHandle")]
        [return: MarshalAs(UnmanagedType.Bool)]
        internal static extern bool
        WimCloseHandle(
            [In]    IntPtr Handle
        );

        [DllImport("Wimgapi.dll", CharSet = CharSet.Unicode, SetLastError = true, EntryPoint = "WIMLoadImage")]
        internal static extern IntPtr
        WimLoadImage(
            [In]    IntPtr Handle,
            [In]    uint ImageIndex
        );

        [DllImport("Wimgapi.dll", CharSet = CharSet.Unicode, SetLastError = true, EntryPoint = "WIMGetImageCount")]
        internal static extern uint
        WimGetImageCount(
            [In]    WimFileHandle Handle
        );

        [DllImport("Wimgapi.dll", CharSet = CharSet.Unicode, SetLastError = true, EntryPoint = "WIMApplyImage")]
        internal static extern bool
        WimApplyImage(
            [In]    WimImageHandle Handle,
            [In, Optional, MarshalAs(UnmanagedType.LPWStr)] string Path,
            [In]    WimApplyFlags Flags
        );

        [DllImport("Wimgapi.dll", CharSet = CharSet.Unicode, SetLastError = true, EntryPoint = "WIMGetImageInformation")]
        [return: MarshalAs(UnmanagedType.Bool)]
        internal static extern bool
        WimGetImageInformation(
            [In]        SafeHandle Handle,
            [Out]   out StringBuilder ImageInfo,
            [Out]   out uint SizeOfImageInfo
        );

        [DllImport("Wimgapi.dll", CharSet = CharSet.Unicode, SetLastError = true, EntryPoint = "WIMSetTemporaryPath")]
        [return: MarshalAs(UnmanagedType.Bool)]
        internal static extern bool
        WimSetTemporaryPath(
            [In]    WimFileHandle Handle,
            [In]    string TempPath
        );

        [DllImport("Wimgapi.dll", CharSet = CharSet.Unicode, SetLastError = true, EntryPoint = "WIMRegisterMessageCallback", CallingConvention = CallingConvention.StdCall)]
        internal static extern uint
        WimRegisterMessageCallback(
            [In, Optional] WimFileHandle      hWim,
            [In]           WimMessageCallback MessageProc,
            [In, Optional] IntPtr             ImageInfo
        );

        [DllImport("Wimgapi.dll", CharSet = CharSet.Unicode, SetLastError = true, EntryPoint = "WIMUnregisterMessageCallback", CallingConvention = CallingConvention.StdCall)]
        [return: MarshalAs(UnmanagedType.Bool)]
        internal static extern bool
        WimUnregisterMessageCallback(
            [In, Optional] WimFileHandle      hWim,
            [In]           WimMessageCallback MessageProc
        );


        #endregion WIMGAPI P/Invoke
    }

    #region WIM Interop

    public class WimFile {

        internal XDocument m_xmlInfo;
        internal List<WimImage> m_imageList;

        private static NativeMethods.WimMessageCallback wimMessageCallback;
        
        #region Events
        
        /// <summary>
        /// DefaultImageEvent handler
        /// </summary>
        public delegate void DefaultImageEventHandler(object sender, DefaultImageEventArgs e);

        ///<summary>
        ///ProcessFileEvent handler
        ///</summary>
        public delegate void ProcessFileEventHandler(object sender, ProcessFileEventArgs e);
                
        ///<summary>
        ///Enable the caller to prevent a file resource from being compressed during a capture.
        ///</summary>
        public event ProcessFileEventHandler ProcessFileEvent;

        ///<summary>
        ///Indicate an update in the progress of an image application.
        ///</summary>
        public event DefaultImageEventHandler ProgressEvent;

        ///<summary>
        ///Alert the caller that an error has occurred while capturing or applying an image.
        ///</summary>
        public event DefaultImageEventHandler ErrorEvent;

        ///<summary>
        ///Indicate that a file has been either captured or applied.
        ///</summary>
        public event DefaultImageEventHandler StepItEvent;

        ///<summary>
        ///Indicate the number of files that will be captured or applied.
        ///</summary>
        public event DefaultImageEventHandler SetRangeEvent;

        ///<summary>
        ///Indicate the number of files that have been captured or applied.
        ///</summary>
        public event DefaultImageEventHandler SetPosEvent;

        #endregion Events

        private
        enum
        ImageEventMessage : uint {
            ///<summary>
            ///Enables the caller to prevent a file or a directory from being captured or applied.
            ///</summary>
            Progress = NativeMethods.WimMessage.WIM_MSG_PROGRESS,
            ///<summary>
            ///Notification sent to enable the caller to prevent a file or a directory from being captured or applied.
            ///To prevent a file or a directory from being captured or applied, call WindowsImageContainer.SkipFile().
            ///</summary>
            Process = NativeMethods.WimMessage.WIM_MSG_PROCESS,
            ///<summary>
            ///Enables the caller to prevent a file resource from being compressed during a capture.
            ///</summary>
            Compress = NativeMethods.WimMessage.WIM_MSG_COMPRESS,
            ///<summary>
            ///Alerts the caller that an error has occurred while capturing or applying an image.
            ///</summary>
            Error = NativeMethods.WimMessage.WIM_MSG_ERROR,
            ///<summary>
            ///Enables the caller to align a file resource on a particular alignment boundary.
            ///</summary>
            Alignment = NativeMethods.WimMessage.WIM_MSG_ALIGNMENT,
            ///<summary>
            ///Enables the caller to align a file resource on a particular alignment boundary.
            ///</summary>
            Split = NativeMethods.WimMessage.WIM_MSG_SPLIT,
            ///<summary>
            ///Indicates that volume information is being gathered during an image capture.
            ///</summary>
            Scanning = NativeMethods.WimMessage.WIM_MSG_SCANNING,
            ///<summary>
            ///Indicates the number of files that will be captured or applied.
            ///</summary>
            SetRange = NativeMethods.WimMessage.WIM_MSG_SETRANGE,
            ///<summary>
            ///Indicates the number of files that have been captured or applied.
            /// </summary>
            SetPos = NativeMethods.WimMessage.WIM_MSG_SETPOS,
            ///<summary>
            ///Indicates that a file has been either captured or applied.
            ///</summary>
            StepIt = NativeMethods.WimMessage.WIM_MSG_STEPIT,
            ///<summary>
            ///Success.
            ///</summary>
            Success = NativeMethods.WimMessage.WIM_MSG_SUCCESS,
            ///<summary>
            ///Abort.
            ///</summary>
            Abort = NativeMethods.WimMessage.WIM_MSG_ABORT_IMAGE
        }

        ///<summary>
        ///Event callback to the Wimgapi events
        ///</summary>
        private        
        uint
        ImageEventMessagePump(
            uint MessageId,
            IntPtr wParam,
            IntPtr lParam,
            IntPtr UserData) {

            uint status = (uint) NativeMethods.WimMessage.WIM_MSG_SUCCESS;

            DefaultImageEventArgs eventArgs = new DefaultImageEventArgs(wParam, lParam, UserData);

            switch ((ImageEventMessage)MessageId) {

                case ImageEventMessage.Progress:
                    ProgressEvent(this, eventArgs);
                    break;

                case ImageEventMessage.Process:
                    if (null != ProcessFileEvent) {
                        string fileToImage = Marshal.PtrToStringUni(wParam);
                        ProcessFileEventArgs fileToProcess = new ProcessFileEventArgs(fileToImage, lParam);
                        ProcessFileEvent(this, fileToProcess);

                        if (fileToProcess.Abort == true) {
                            status = (uint)ImageEventMessage.Abort;
                        }
                    }
                    break;

                case ImageEventMessage.Error:
                    if (null != ErrorEvent) {
                        ErrorEvent(this, eventArgs);
                    }
                    break;
                    
                case ImageEventMessage.SetRange:
                    if (null != SetRangeEvent) {
                        SetRangeEvent(this, eventArgs);
                    }
                    break;

                case ImageEventMessage.SetPos:
                    if (null != SetPosEvent) {
                        SetPosEvent(this, eventArgs);
                    }
                    break;

                case ImageEventMessage.StepIt:
                    if (null != StepItEvent) {
                        StepItEvent(this, eventArgs);
                    }
                    break;

                default:
                    break;
            }
            return status;
            
        }

        /// <summary>
        /// Constructor.
        /// </summary>
        /// <param name="wimPath">Path to the WIM container.</param>
        public
        WimFile(string wimPath) {
            if (string.IsNullOrEmpty(wimPath)) {
                throw new ArgumentNullException("wimPath");
            }

            if (!File.Exists(Path.GetFullPath(wimPath))) {
                throw new FileNotFoundException((new FileNotFoundException()).Message, wimPath);
            }

            Handle = new NativeMethods.WimFileHandle(wimPath);

            // Hook up the events before we return.
            //wimMessageCallback = new NativeMethods.WimMessageCallback(ImageEventMessagePump);
            //NativeMethods.RegisterMessageCallback(this.Handle, wimMessageCallback);
        }

        /// <summary>
        /// Closes the WIM file.
        /// </summary>
        public void
        Close() {
            foreach (WimImage image in Images) {
                image.Close();
            }

            if (null != wimMessageCallback) {
                NativeMethods.UnregisterMessageCallback(this.Handle, wimMessageCallback);
                wimMessageCallback = null;
            }

            if ((!Handle.IsClosed) && (!Handle.IsInvalid)) {
                Handle.Close();
            }
        }

        /// <summary>
        /// Provides a list of WimImage objects, representing the images in the WIM container file.
        /// </summary>
        public List<WimImage>
        Images {
            get {
                if (null == m_imageList) {

                    int imageCount = (int)ImageCount;
                    m_imageList = new List<WimImage>(imageCount);
                    for (int i = 0; i < imageCount; i++) {

                        // Load up each image so it's ready for us.
                        m_imageList.Add(
                            new WimImage(this, (uint)i + 1));
                    }
                }

                return m_imageList;
            }
        }

        /// <summary>
        /// Provides a list of names of the images in the specified WIM container file.
        /// </summary>
        public List<string>
        ImageNames {
            get {
                List<string> nameList = new List<string>();
                foreach (WimImage image in Images) {
                    nameList.Add(image.ImageName);
                }
                return nameList;
            }
        }

        /// <summary>
        /// Indexer for WIM images inside the WIM container, indexed by the image number.
        /// The list of Images is 0-based, but the WIM container is 1-based, so we automatically compensate for that.
        /// this[1] returns the 0th image in the WIM container.
        /// </summary>
        /// <param name="ImageIndex">The 1-based index of the image to retrieve.</param>
        /// <returns>WinImage object.</returns>
        public WimImage
        this[int ImageIndex] {
            get { return Images[ImageIndex - 1]; }
        }

        /// <summary>
        /// Indexer for WIM images inside the WIM container, indexed by the image name.
        /// WIMs created by different processes sometimes contain different information - including the name.
        /// Some images have their name stored in the Name field, some in the Flags field, and some in the EditionID field.
        /// We take all of those into account in while searching the WIM.
        /// </summary>
        /// <param name="ImageName"></param>
        /// <returns></returns>
        public WimImage
        this[string ImageName] {
            get {
                return
                    Images.Where(i => (
                        i.ImageName.ToUpper()  == ImageName.ToUpper() ||
                        i.ImageFlags.ToUpper() == ImageName.ToUpper() ))
                    .DefaultIfEmpty(null)
                        .FirstOrDefault<WimImage>();
            }
        }

        /// <summary>
        /// Returns the number of images in the WIM container.
        /// </summary>
        internal uint
        ImageCount {
            get { return NativeMethods.WimGetImageCount(Handle); }
        }

        /// <summary>
        /// Returns an XDocument representation of the XML metadata for the WIM container and associated images.
        /// </summary>
        internal XDocument
        XmlInfo {
            get {

                if (null == m_xmlInfo) {
                    StringBuilder builder;
                    uint bytes;
                    if (!NativeMethods.WimGetImageInformation(Handle, out builder, out bytes)) {
                        throw new Win32Exception();
                    }

                    // Ensure the length of the returned bytes to avoid garbage characters at the end.
                    int charCount = (int)bytes / sizeof(char);
                    if (null != builder) {
                        // Get rid of the unicode file marker at the beginning of the XML.
                        builder.Remove(0, 1);
                        builder.EnsureCapacity(charCount - 1);
                        builder.Length = charCount - 1;

                        // This isn't likely to change while we have the image open, so cache it.
                        m_xmlInfo = XDocument.Parse(builder.ToString().Trim());
                    } else {
                        m_xmlInfo = null;
                    }
                }

                return m_xmlInfo;
            }
        }

        public NativeMethods.WimFileHandle Handle {
            get;
            private set;
        }
    }

    public class
    WimImage {

        internal XDocument m_xmlInfo;

        public
        WimImage(
            WimFile Container,
            uint ImageIndex) {

            if (null == Container) {
                throw new ArgumentNullException("Container");
            }

            if ((Container.Handle.IsClosed) || (Container.Handle.IsInvalid)) {
                throw new ArgumentNullException("The handle to the WIM file has already been closed, or is invalid.", "Container");
            }

            if (ImageIndex > Container.ImageCount) {
                throw new ArgumentOutOfRangeException("ImageIndex", "The index does not exist in the specified WIM file.");
            }

            Handle = new NativeMethods.WimImageHandle(Container, ImageIndex);            
        }

        public enum
        Architectures : uint {
            x86   = 0x0,
            ARM   = 0x5,
            IA64  = 0x6,
            AMD64 = 0x9
        }

        public void
        Close() {
            if ((!Handle.IsClosed) && (!Handle.IsInvalid)) {
                Handle.Close();
            }
        }

        public void
        Apply(
            string ApplyToPath) {

            if (string.IsNullOrEmpty(ApplyToPath)) {
                throw new ArgumentNullException("ApplyToPath");
            }

            ApplyToPath = Path.GetFullPath(ApplyToPath);

            if (!Directory.Exists(ApplyToPath)) {
                throw new DirectoryNotFoundException("The WIM cannot be applied because the specified directory was not found.");
            }

            if (!NativeMethods.WimApplyImage(
                this.Handle,
                ApplyToPath,
                NativeMethods.WimApplyFlags.WimApplyFlagsNone
            )) {
                throw new Win32Exception();
            }
        }

        public NativeMethods.WimImageHandle
        Handle {
            get;
            private set;
        }

        internal XDocument
        XmlInfo {
            get {

                if (null == m_xmlInfo) {
                    StringBuilder builder;
                    uint bytes;
                    if (!NativeMethods.WimGetImageInformation(Handle, out builder, out bytes)) {
                        throw new Win32Exception();
                    }

                    // Ensure the length of the returned bytes to avoid garbage characters at the end.
                    int charCount = (int)bytes / sizeof(char);
                    if (null != builder) {
                        // Get rid of the unicode file marker at the beginning of the XML.
                        builder.Remove(0, 1);
                        builder.EnsureCapacity(charCount - 1);
                        builder.Length = charCount - 1;

                        // This isn't likely to change while we have the image open, so cache it.
                        m_xmlInfo = XDocument.Parse(builder.ToString().Trim());
                    } else {
                        m_xmlInfo = null;
                    }
                }

                return m_xmlInfo;
            }
        }

        public string 
        ImageIndex {
            get { return XmlInfo.Element("IMAGE").Attribute("INDEX").Value; }
        }

        public string
        ImageName {
            get { return XmlInfo.XPathSelectElement("/IMAGE/NAME").Value; }
        }

        public string
        ImageEditionId {
            get { return XmlInfo.XPathSelectElement("/IMAGE/WINDOWS/EDITIONID").Value; }
        }

        public string
        ImageFlags {
            get { return XmlInfo.XPathSelectElement("/IMAGE/FLAGS").Value; }
        }

        public string
        ImageProductType {
            get {
                return XmlInfo.XPathSelectElement("/IMAGE/WINDOWS/PRODUCTTYPE").Value;
            }
        }

        public string
        ImageInstallationType {
            get { return XmlInfo.XPathSelectElement("/IMAGE/WINDOWS/INSTALLATIONTYPE").Value; }
        }

        public string
        ImageDescription {
            get { return XmlInfo.XPathSelectElement("/IMAGE/DESCRIPTION").Value; }
        }

        public ulong
        ImageSize {
            get { return ulong.Parse(XmlInfo.XPathSelectElement("/IMAGE/TOTALBYTES").Value); }
        }

        public Architectures
        ImageArchitecture {
            get {
                int arch = -1;
                try {
                    arch = int.Parse(XmlInfo.XPathSelectElement("/IMAGE/WINDOWS/ARCH").Value);
                } catch { }

                return (Architectures)arch;
            }
        }

        public string
        ImageDefaultLanguage {
            get {
                string lang = null;
                try {
                    lang = XmlInfo.XPathSelectElement("/IMAGE/WINDOWS/LANGUAGES/DEFAULT").Value;
                } catch { }

                return lang;
            }
        }

        public Version
        ImageVersion {
            get {
                int major = 0;
                int minor = 0;
                int build = 0;
                int revision = 0;

                try {
                    major = int.Parse(XmlInfo.XPathSelectElement("/IMAGE/WINDOWS/VERSION/MAJOR").Value);
                    minor = int.Parse(XmlInfo.XPathSelectElement("/IMAGE/WINDOWS/VERSION/MINOR").Value);
                    build = int.Parse(XmlInfo.XPathSelectElement("/IMAGE/WINDOWS/VERSION/BUILD").Value);
                    revision = int.Parse(XmlInfo.XPathSelectElement("/IMAGE/WINDOWS/VERSION/SPBUILD").Value);
                } catch { }

                return (new Version(major, minor, build, revision));
            }
        }

        public string
        ImageDisplayName {
            get { return XmlInfo.XPathSelectElement("/IMAGE/DISPLAYNAME").Value; }
        }

        public string
        ImageDisplayDescription {
            get { return XmlInfo.XPathSelectElement("/IMAGE/DISPLAYDESCRIPTION").Value; }
        }
    }

    ///<summary>
    ///Describes the file that is being processed for the ProcessFileEvent.
    ///</summary>
    public class
    DefaultImageEventArgs : EventArgs {
        ///<summary>
        ///Default constructor.
        ///</summary>
        public
        DefaultImageEventArgs(
            IntPtr wideParameter, 
            IntPtr leftParameter, 
            IntPtr userData) {
            
            WideParameter = wideParameter;
            LeftParameter = leftParameter;
            UserData      = userData;
        }

        ///<summary>
        ///wParam
        ///</summary>
        public IntPtr WideParameter {
            get;
            private set;
        }

        ///<summary>
        ///lParam
        ///</summary>
        public IntPtr LeftParameter {
            get;
            private set;
        }

        ///<summary>
        ///UserData
        ///</summary>
        public IntPtr UserData {
            get;
            private set;
        }
    }

    ///<summary>
    ///Describes the file that is being processed for the ProcessFileEvent.
    ///</summary>
    public class
    ProcessFileEventArgs : EventArgs {
        ///<summary>
        ///Default constructor.
        ///</summary>
        ///<param name="file">Fully qualified path and file name. For example: c:\file.sys.</param>
        ///<param name="skipFileFlag">Default is false - skip file and continue.
        ///Set to true to abort the entire image capture.</param>
        public
        ProcessFileEventArgs(
            string file, 
            IntPtr skipFileFlag) {

            m_FilePath = file;
            m_SkipFileFlag = skipFileFlag;
        }

        ///<summary>
        ///Skip file from being imaged.
        ///</summary>
        public void
        SkipFile() {
            byte[] byteBuffer = {
                    0
            };
            int byteBufferSize = byteBuffer.Length;
            Marshal.Copy(byteBuffer, 0, m_SkipFileFlag, byteBufferSize);
        }

        ///<summary>
        ///Fully qualified path and file name.
        ///</summary>
        public string 
        FilePath {
            get {
                string stringToReturn = "";
                if (m_FilePath != null) {
                    stringToReturn = m_FilePath;
                }
                return stringToReturn;
            }
        }

        ///<summary>
        ///Flag to indicate if the entire image capture should be aborted.
        ///Default is false - skip file and continue. Setting to true will
        ///abort the entire image capture.
        ///</summary>
        public bool Abort {
            set { m_Abort = value; }
            get { return m_Abort;  }
        }

        private string m_FilePath;
        private bool m_Abort;
        private IntPtr m_SkipFileFlag;

    }

    #endregion WIM Interop

    #region VHD Interop
    // Based on code written by the Hyper-V Test team.
    /// <summary>
    /// The Virtual Hard Disk class provides methods for creating and manipulating Virtual Hard Disk files.
    /// </summary>
    public class
    VirtualHardDisk : IDisposable {

        #region Member Variables

        private SafeFileHandle m_virtualHardDiskHandle = null;
        private string m_filePath = null;
        private bool m_isDisposed;
        private NativeMethods.VirtualStorageDeviceType m_deviceType = NativeMethods.VirtualStorageDeviceType.Unknown;

        #endregion Member Variables

        #region IDisposable Members

        /// <summary>
        /// Disposal method for Virtual Hard Disk objects.
        /// </summary>
        public void
        Dispose() {
            this.Dispose(true);
            GC.SuppressFinalize(this);
        }

        /// <summary>
        /// Disposal method for Virtual Hard Disk objects.
        /// </summary>
        /// <param name="disposing"></param>
        public void
        Dispose(
            bool disposing) {
            // Check to see if Dispose has already been called.
            if (!this.m_isDisposed) {
                // If disposing equals true, dispose all managed
                // and unmanaged resources.
                if (disposing) {
                    // Dispose managed resources.
                    if (this.DiskIndex != 0) {
                        this.Close();
                    }
                }

                // Call the appropriate methods to clean up
                // unmanaged resources here.
                // If disposing is false,
                // only the following code is executed.

                // Note disposing has been done.
                m_isDisposed = true;
            }
        }

        #endregion IDisposable Members

        #region Constructor

        private VirtualHardDisk(
            SafeFileHandle Handle,
            string Path,
            NativeMethods.VirtualStorageDeviceType DeviceType) {
            if (Handle.IsInvalid || Handle.IsClosed) {
                throw new InvalidOperationException("The handle to the Virtual Hard Disk is invalid.");
            }

            m_virtualHardDiskHandle = Handle;
            m_filePath = Path;
            m_deviceType = DeviceType;
        }

        #endregion Constructor

        #region Gozer the Destructor
        /// <summary>
        /// Destroys a VHD object.
        /// </summary>
        ~VirtualHardDisk() {
            this.Dispose(false);
        }

        #endregion Gozer the Destructor

        #region Static Methods

        #region Sparse Disks

        /// <summary>
        /// Abbreviated signature of CreateSparseDisk so it's easier to use from WIM2VHD.
        /// </summary>
        /// <param name="virtualStorageDeviceType">The type of disk to create, VHD or VHDX.</param>
        /// <param name="path">The path of the disk to create.</param>
        /// <param name="size">The maximum size of the disk to create.</param>
        /// <param name="overwrite">Overwrite the VHD if it already exists.</param>
        /// <returns>Virtual Hard Disk object</returns>
        public static VirtualHardDisk
        CreateSparseDisk(
            NativeMethods.VirtualStorageDeviceType virtualStorageDeviceType,
            string path,
            ulong size,
            bool overwrite) {

            return CreateSparseDisk(
                path,
                size,
                overwrite,
                null,
                IntPtr.Zero,
                (virtualStorageDeviceType == NativeMethods.VirtualStorageDeviceType.VHD) 
                    ? NativeMethods.DEFAULT_BLOCK_SIZE
                    : 0,
                virtualStorageDeviceType,
                NativeMethods.DISK_SECTOR_SIZE);
        }

        /// <summary>
        /// Creates a new sparse (dynamically expanding) virtual hard disk (.vhd). Supports both sync and async modes.
        /// The VHD image file uses only as much space on the backing store as needed to store the actual data the VHD currently contains. 
        /// </summary>
        /// <param name="path">The path and name of the VHD to create.</param>
        /// <param name="size">The size of the VHD to create in bytes.  
        /// When creating this type of VHD, the VHD API does not test for free space on the physical backing store based on the maximum size requested, 
        /// therefore it is possible to successfully create a dynamic VHD with a maximum size larger than the available physical disk free space.
        /// The maximum size of a dynamic VHD is 2,040 GB.  The minimum size is 3 MB.</param>
        /// <param name="source">Optional path to pre-populate the new virtual disk object with block data from an existing disk
        /// This path may refer to a VHD or a physical disk.  Use NULL if you don't want a source.</param>
        /// <param name="overwrite">If the VHD exists, setting this parameter to 'True' will delete it and create a new one.</param>
        /// <param name="overlapped">If not null, the operation runs in async mode</param>
        /// <param name="blockSizeInBytes">Block size for the VHD.</param>
        /// <param name="virtualStorageDeviceType">VHD format version (VHD1 or VHD2)</param>
        /// <param name="sectorSizeInBytes">Sector size for the VHD.</param>
        /// <returns>Returns a SafeFileHandle corresponding to the virtual hard disk that was created.</returns>
        /// <exception cref="ArgumentOutOfRangeException">Thrown when an invalid size is specified</exception>
        /// <exception cref="FileNotFoundException">Thrown when source VHD is not found.</exception>
        /// <exception cref="SecurityException">Thrown when there was an error while creating the default security descriptor.</exception>
        /// <exception cref="Win32Exception">Thrown when an error occurred while creating the VHD.</exception>
        public static VirtualHardDisk
        CreateSparseDisk(
            string path,
            ulong size,
            bool overwrite,
            string source,
            IntPtr overlapped,
            uint blockSizeInBytes,
            NativeMethods.VirtualStorageDeviceType virtualStorageDeviceType,
            uint sectorSizeInBytes) {

            // Validate the virtualStorageDeviceType
            if (virtualStorageDeviceType != NativeMethods.VirtualStorageDeviceType.VHD && virtualStorageDeviceType != NativeMethods.VirtualStorageDeviceType.VHDX) {

                throw (
                    new ArgumentOutOfRangeException(
                        "virtualStorageDeviceType",
                        virtualStorageDeviceType,
                        "VirtualStorageDeviceType must be VHD or VHDX."
                ));
            }

            // Validate size.  It needs to be a multiple of DISK_SECTOR_SIZE (512)...
            if ((size % NativeMethods.DISK_SECTOR_SIZE) != 0) {

                throw (
                    new ArgumentOutOfRangeException(
                        "size", 
                        size, 
                        "The size of the virtual disk must be a multiple of 512."
                ));
            }

            if ((!String.IsNullOrEmpty(source)) && (!System.IO.File.Exists(source))) {

                throw (
                    new System.IO.FileNotFoundException(
                        "Unable to find the source file.",
                        source
                ));
            }

            if ((overwrite) && (System.IO.File.Exists(path))) {

                System.IO.File.Delete(path);
            }

            NativeMethods.CreateVirtualDiskParameters createParams = new NativeMethods.CreateVirtualDiskParameters();

            // Select the correct version.
            createParams.Version = (virtualStorageDeviceType == NativeMethods.VirtualStorageDeviceType.VHD)
                ? NativeMethods.CreateVirtualDiskVersion.Version1
                : NativeMethods.CreateVirtualDiskVersion.Version2;

            createParams.UniqueId                 = Guid.NewGuid();
            createParams.MaximumSize              = size;
            createParams.BlockSizeInBytes         = blockSizeInBytes;
            createParams.SectorSizeInBytes        = sectorSizeInBytes;
            createParams.ParentPath               = null;
            createParams.SourcePath               = source;
            createParams.OpenFlags                = NativeMethods.OpenVirtualDiskFlags.None;
            createParams.GetInfoOnly              = false;
            createParams.ParentVirtualStorageType = new NativeMethods.VirtualStorageType();
            createParams.SourceVirtualStorageType = new NativeMethods.VirtualStorageType();

            //
            // Create and init a security descriptor.
            // Since we're creating an essentially blank SD to use with CreateVirtualDisk
            // the VHD will take on the security values from the parent directory.
            //

            NativeMethods.SecurityDescriptor securityDescriptor;
            if (!NativeMethods.InitializeSecurityDescriptor(out securityDescriptor, 1)) {

                throw (
                    new SecurityException(
                        "Unable to initialize the security descriptor for the virtual disk."
                ));
            }

            NativeMethods.VirtualStorageType virtualStorageType = new NativeMethods.VirtualStorageType();
            virtualStorageType.DeviceId = virtualStorageDeviceType;
            virtualStorageType.VendorId = NativeMethods.VirtualStorageTypeVendorMicrosoft;

            SafeFileHandle vhdHandle;

            uint returnCode = NativeMethods.CreateVirtualDisk(
                ref virtualStorageType,
                    path,
                    (virtualStorageDeviceType == NativeMethods.VirtualStorageDeviceType.VHD)
                        ? NativeMethods.VirtualDiskAccessMask.All
                        : NativeMethods.VirtualDiskAccessMask.None,
                ref securityDescriptor,
                    NativeMethods.CreateVirtualDiskFlags.None,
                    0,
                ref createParams,
                    overlapped,
                out vhdHandle);

            if (NativeMethods.ERROR_SUCCESS != returnCode && NativeMethods.ERROR_IO_PENDING != returnCode) {

                throw (
                    new Win32Exception(
                        (int)returnCode
                ));
            }

            return new VirtualHardDisk(vhdHandle, path, virtualStorageDeviceType);
        }

        #endregion Sparse Disks

        #region Fixed Disks

        /// <summary>
        /// Abbreviated signature of CreateFixedDisk so it's easier to use from WIM2VHD.
        /// </summary>
        /// <param name="virtualStorageDeviceType">The type of disk to create, VHD or VHDX.</param>
        /// <param name="path">The path of the disk to create.</param>
        /// <param name="size">The maximum size of the disk to create.</param>
        /// <param name="overwrite">Overwrite the VHD if it already exists.</param>
        /// <returns>Virtual Hard Disk object</returns>
        public static VirtualHardDisk
        CreateFixedDisk(
            NativeMethods.VirtualStorageDeviceType virtualStorageDeviceType,
            string path,
            ulong size,
            bool overwrite) {

            return CreateFixedDisk(
                path,
                size,
                overwrite,
                null,
                IntPtr.Zero,
                0,
                virtualStorageDeviceType,
                NativeMethods.DISK_SECTOR_SIZE);
        }

        /// <summary>
        /// Creates a fixed-size Virtual Hard Disk. Supports both sync and async modes. This methods always calls the V2 version of the 
        /// CreateVirtualDisk API, and creates VHD2. 
        /// </summary>
        /// <param name="path">The path and name of the VHD to create.</param>
        /// <param name="size">The size of the VHD to create in bytes.  
        /// The VHD image file is pre-allocated on the backing store for the maximum size requested.
        /// The maximum size of a dynamic VHD is 2,040 GB.  The minimum size is 3 MB.</param>
        /// <param name="source">Optional path to pre-populate the new virtual disk object with block data from an existing disk
        /// This path may refer to a VHD or a physical disk.  Use NULL if you don't want a source.</param>
        /// <param name="overwrite">If the VHD exists, setting this parameter to 'True' will delete it and create a new one.</param>
        /// <param name="overlapped">If not null, the operation runs in async mode</param>
        /// <param name="blockSizeInBytes">Block size for the VHD.</param>
        /// <param name="virtualStorageDeviceType">Virtual storage device type: VHD1 or VHD2.</param>
        /// <param name="sectorSizeInBytes">Sector size for the VHD.</param>
        /// <returns>Returns a SafeFileHandle corresponding to the virtual hard disk that was created.</returns>
        /// <remarks>Creating a fixed disk can be a time consuming process!</remarks>  
        /// <exception cref="ArgumentOutOfRangeException">Thrown when an invalid size or wrong virtual storage device type is specified.</exception>
        /// <exception cref="FileNotFoundException">Thrown when source VHD is not found.</exception>
        /// <exception cref="SecurityException">Thrown when there was an error while creating the default security descriptor.</exception>
        /// <exception cref="Win32Exception">Thrown when an error occurred while creating the VHD.</exception>
        public static VirtualHardDisk
        CreateFixedDisk(
            string path,
            ulong size,
            bool overwrite,
            string source,
            IntPtr overlapped,
            uint blockSizeInBytes,
            NativeMethods.VirtualStorageDeviceType virtualStorageDeviceType,
            uint sectorSizeInBytes) {

            // Validate the virtualStorageDeviceType
            if (virtualStorageDeviceType != NativeMethods.VirtualStorageDeviceType.VHD && virtualStorageDeviceType != NativeMethods.VirtualStorageDeviceType.VHDX) {

                throw (
                    new ArgumentOutOfRangeException(
                        "virtualStorageDeviceType",
                        virtualStorageDeviceType,
                        "VirtualStorageDeviceType must be VHD or VHDX."
                ));
            }

            // Validate size.  It needs to be a multiple of DISK_SECTOR_SIZE (512)...
            if ((size % NativeMethods.DISK_SECTOR_SIZE) != 0) {

                throw (
                    new ArgumentOutOfRangeException(
                        "size",
                        size,
                        "The size of the virtual disk must be a multiple of 512."
                ));
            }

            if ((!String.IsNullOrEmpty(source)) && (!System.IO.File.Exists(source))) {

                throw (
                    new System.IO.FileNotFoundException(
                        "Unable to find the source file.",
                        source
                ));
            }

            if ((overwrite) && (System.IO.File.Exists(path))) {

                System.IO.File.Delete(path);
            }

            NativeMethods.CreateVirtualDiskParameters createParams = new NativeMethods.CreateVirtualDiskParameters();

            // Select the correct version.
            createParams.Version = (virtualStorageDeviceType == NativeMethods.VirtualStorageDeviceType.VHD)
                ? NativeMethods.CreateVirtualDiskVersion.Version1
                : NativeMethods.CreateVirtualDiskVersion.Version2;

            createParams.UniqueId                 = Guid.NewGuid();
            createParams.MaximumSize              = size;
            createParams.BlockSizeInBytes         = blockSizeInBytes;
            createParams.SectorSizeInBytes        = sectorSizeInBytes;
            createParams.ParentPath               = null;
            createParams.SourcePath               = source;
            createParams.OpenFlags                = NativeMethods.OpenVirtualDiskFlags.None;
            createParams.GetInfoOnly              = false;
            createParams.ParentVirtualStorageType = new NativeMethods.VirtualStorageType();
            createParams.SourceVirtualStorageType = new NativeMethods.VirtualStorageType();

            //
            // Create and init a security descriptor.
            // Since we're creating an essentially blank SD to use with CreateVirtualDisk
            // the VHD will take on the security values from the parent directory.
            //

            NativeMethods.SecurityDescriptor securityDescriptor;
            if (!NativeMethods.InitializeSecurityDescriptor(out securityDescriptor, 1)) {
                throw (
                    new SecurityException(
                        "Unable to initialize the security descriptor for the virtual disk."
                ));
            }

            NativeMethods.VirtualStorageType virtualStorageType = new NativeMethods.VirtualStorageType();
            virtualStorageType.DeviceId = virtualStorageDeviceType;
            virtualStorageType.VendorId = NativeMethods.VirtualStorageTypeVendorMicrosoft;

            SafeFileHandle vhdHandle;

            uint returnCode = NativeMethods.CreateVirtualDisk(
                ref virtualStorageType,
                    path,
                    (virtualStorageDeviceType == NativeMethods.VirtualStorageDeviceType.VHD)
                        ? NativeMethods.VirtualDiskAccessMask.All
                        : NativeMethods.VirtualDiskAccessMask.None,
                ref securityDescriptor,
                    NativeMethods.CreateVirtualDiskFlags.FullPhysicalAllocation,
                    0,
                ref createParams,
                    overlapped,
                out vhdHandle);

            if (NativeMethods.ERROR_SUCCESS != returnCode && NativeMethods.ERROR_IO_PENDING != returnCode) {

                throw (
                    new Win32Exception(
                        (int)returnCode
                ));
            }

            return new VirtualHardDisk(vhdHandle, path, virtualStorageDeviceType);
        }

        #endregion Fixed Disks

        #region Open

        /// <summary>
        /// Opens a virtual hard disk (VHD) using the V2 of OpenVirtualDisk Win32 API for use, allowing you to explicitly specify OpenVirtualDiskFlags, 
        /// Read/Write depth, and Access Mask information.
        /// </summary>
        /// <param name="path">The path and name of the Virtual Hard Disk file to open.</param>
        /// <param name="accessMask">Contains the bit mask for specifying access rights to a virtual hard disk (VHD).  Default is All.</param>
        /// <param name="readWriteDepth">Indicates the number of stores, beginning with the child, of the backing store chain to open as read/write. 
        /// The remaining stores in the differencing chain will be opened read-only. This is necessary for merge operations to succeed.  Default is 0x1.</param>
        /// <param name="flags">An OpenVirtualDiskFlags object to modify the way the Virtual Hard Disk is opened.  Default is Unknown.</param>
        /// <param name="virtualStorageDeviceType">VHD Format Version (VHD1 or VHD2)</param>
        /// <returns>VirtualHardDisk object</returns>
        /// <exception cref="FileNotFoundException">Thrown if the VHD at path is not found.</exception>
        /// <exception cref="Win32Exception">Thrown if an error occurred while opening the VHD.</exception>
        public static VirtualHardDisk
        Open(
            string path,
            NativeMethods.VirtualDiskAccessMask accessMask,
            uint readWriteDepth,
            NativeMethods.OpenVirtualDiskFlags flags,
            NativeMethods.VirtualStorageDeviceType virtualStorageDeviceType) {

            if (!File.Exists(path)) {
                throw new FileNotFoundException("The specified VHD was not found.  Please check your path and try again.", path);
            }

            NativeMethods.OpenVirtualDiskParameters openParams = new NativeMethods.OpenVirtualDiskParameters();

            // Select the correct version.
            openParams.Version = (virtualStorageDeviceType == NativeMethods.VirtualStorageDeviceType.VHD)
                ? NativeMethods.OpenVirtualDiskVersion.Version1
                : NativeMethods.OpenVirtualDiskVersion.Version2;

            openParams.GetInfoOnly = false;

            NativeMethods.VirtualStorageType virtualStorageType = new NativeMethods.VirtualStorageType();
            virtualStorageType.DeviceId = virtualStorageDeviceType;

            virtualStorageType.VendorId = (virtualStorageDeviceType == NativeMethods.VirtualStorageDeviceType.Unknown)
                ? virtualStorageType.VendorId = NativeMethods.VirtualStorageTypeVendorUnknown
                : virtualStorageType.VendorId = NativeMethods.VirtualStorageTypeVendorMicrosoft;

            SafeFileHandle vhdHandle;

            uint returnCode = NativeMethods.OpenVirtualDisk(
                ref virtualStorageType,
                    path,
                    accessMask,
                    flags,
                ref openParams,
                out vhdHandle);

            if (NativeMethods.ERROR_SUCCESS != returnCode) {
                throw new Win32Exception((int)returnCode);
            }

            return new VirtualHardDisk(vhdHandle, path, virtualStorageDeviceType);
        }

        #endregion Open

        #region Other

        /// <summary>
        /// Retrieves a collection of drive letters that are currently available on the system.
        /// </summary>
        /// <remarks>Drives A and B are not included in the collection, even if they are available.</remarks>
        /// <returns>A collection of drive letters that are currently available on the system.</returns>
        public static ReadOnlyCollection<Char>
        GetAvailableDriveLetters() {

            List<Char> availableDrives = new List<Char>();
            for (int i = (byte)'C'; i <= (byte)'Z'; i++) {
                availableDrives.Add((char)i);
            }

            foreach (string drive in System.Environment.GetLogicalDrives()) {
                availableDrives.Remove(drive.ToUpper(CultureInfo.InvariantCulture)[0]);
            }

            return new ReadOnlyCollection<char>(availableDrives);
        }

        /// <summary>
        /// Gets the first available drive letter on the current system.
        /// </summary>
        /// <remarks>Drives A and B will not be returned, even if they are available.</remarks>
        /// <returns>Char representing the first available drive letter.</returns>
        public static char
        GetFirstAvailableDriveLetter() {
            return GetAvailableDriveLetters()[0];
        }

        #endregion Other

        #endregion Static Methods

        #region AsyncHelpers

        /// <summary>
        /// Creates a NativeOverlapped object, initializes its EventHandle property, and pins the object to the memory.
        /// This overlapped objects are useful when executing VHD meta-ops in async mode.
        /// </summary>
        /// <returns>Returns the GCHandle for the pinned overlapped structure</returns>
        public static GCHandle
        CreatePinnedOverlappedObject() {
            NativeOverlapped overlapped = new NativeOverlapped();
            overlapped.EventHandle = NativeMethods.CreateEvent(IntPtr.Zero, true, false, null);

            GCHandle handleForOverllapped = GCHandle.Alloc(overlapped, GCHandleType.Pinned);

            return handleForOverllapped;
        }

        /// <summary>
        /// GetVirtualDiskOperationProgress API allows getting progress info for the async virtual disk operations (ie. Online Mirror)
        /// </summary>
        /// <param name="progress"></param>
        /// <param name="overlapped"></param>
        /// <returns></returns>
        /// <exception cref="Win32Exception">Thrown when an error occurred while mirroring the VHD.</exception>
        public uint
        GetVirtualDiskOperationProgress(
            ref NativeMethods.VirtualDiskProgress progress,
                IntPtr overlapped) {
            uint returnCode = NativeMethods.GetVirtualDiskOperationProgress(
                    this.m_virtualHardDiskHandle,
                    overlapped,
                ref progress);

            return returnCode;
        }

        #endregion AsyncHelpers

        #region Public Methods

        /// <summary>
        /// Closes all open handles to the Virtual Hard Disk object.
        /// If the VHD is currently attached, and the PermanentLifetime was not specified, this operation will detach it.
        /// </summary>
        public void
        Close() {
            m_virtualHardDiskHandle.Close();
        }

        /// <summary>
        /// Attaches a virtual hard disk (VHD) by locating an appropriate VHD provider to accomplish the attachment.
        /// </summary>
        /// <param name="attachVirtualDiskFlags">
        /// A combination of values from the attachVirtualDiskFlags enumeration which will dictate how the behavior of the VHD once mounted.
        /// </param>
        /// <exception cref="Win32Exception">Thrown when an error occurred while attaching the VHD.</exception>
        /// <exception cref="SecurityException">Thrown when an error occurred while creating the default security descriptor.</exception>
        public void
        Attach(
            NativeMethods.AttachVirtualDiskFlags attachVirtualDiskFlags) {

            if (!this.IsAttached) {

                // Get the current disk index.  We need it later.
                int diskIndex = this.DiskIndex;

                NativeMethods.AttachVirtualDiskParameters attachParameters = new NativeMethods.AttachVirtualDiskParameters();

                // For attach, the correct version is always Version1 for Win7 and Win8.
                attachParameters.Version = NativeMethods.AttachVirtualDiskVersion.Version1;
                attachParameters.Reserved = 0;

                NativeMethods.SecurityDescriptor securityDescriptor;
                if (!NativeMethods.InitializeSecurityDescriptor(out securityDescriptor, 1)) {

                    throw (new SecurityException("Unable to initialize the security descriptor for the virtual disk."));
                }

                uint returnCode = NativeMethods.AttachVirtualDisk(
                         m_virtualHardDiskHandle,
                    ref  securityDescriptor,
                         attachVirtualDiskFlags,
                         0,
                    ref  attachParameters,
                         IntPtr.Zero);

                switch (returnCode) {

                    case NativeMethods.ERROR_SUCCESS:
                        break;

                    default:
                        throw new Win32Exception((int)returnCode);
                }

                // There's apparently a bit of a timing issue here on some systems.
                // If the disk index isn't updated, keep checking once per second for five seconds.
                // If it's not updated after that, it's probably not our fault.
                short attempts = 5;
                while ((attempts-- >= 0) && (diskIndex == this.DiskIndex)) {
                    System.Threading.Thread.Sleep(1000);
                }
            }
        }

        /// <summary>
        /// Attaches a virtual hard disk (VHD) by locating an appropriate VHD provider to accomplish the attachment.
        /// </summary>
        /// <remarks>
        /// This method attaches the VHD with no flags.
        /// </remarks>
        /// <exception cref="Win32Exception">Thrown when an error occurred while attaching the VHD.</exception>
        /// <exception cref="SecurityException">Thrown when an error occurred while creating the default security descriptor.</exception>
        public void
        Attach() {

            this.Attach(NativeMethods.AttachVirtualDiskFlags.None);
        }

        /// <summary>
        /// Unsurfaces (detaches) a virtual hard disk (VHD) by locating an appropriate VHD provider to accomplish the operation.
        /// </summary>
        public void
        Detach() {

            if (this.IsAttached) {
                uint returnCode = NativeMethods.DetachVirtualDisk(
                    m_virtualHardDiskHandle,
                    NativeMethods.DetachVirtualDiskFlag.None,
                    0);

                switch (returnCode) {

                    case NativeMethods.ERROR_NOT_FOUND:
                    // There's nothing to do here.  The device wasn't found, which means there's a 
                    // really good chance that it wasn't attached to begin with.
                    // And, since we were asked to detach it anyway, we can assume that the system
                    // is already in the desired state.
                    case NativeMethods.ERROR_SUCCESS:
                        break;

                    default:
                        throw new Win32Exception((int)returnCode);
                }
            }
        }

        /// <summary>
        /// Reduces the size of the virtual hard disk (VHD) backing store file. Supports both sync and async modes.
        /// </summary>
        /// <param name="overlapped">If not null, the operation runs in async mode</param>
        public uint
        Compact(IntPtr overlapped) {
            return this.Compact(
                overlapped,
                NativeMethods.CompactVirtualDiskFlags.None);
        }

        /// <summary>
        /// Reduces the size of the virtual hard disk (VHD) backing store file. Supports both sync and async modes.
        /// </summary>
        /// <param name="overlapped">If not null, the operation runs in async mode</param>
        /// <param name="flags">Flags for Compact operation</param>
        public uint
        Compact(
            IntPtr overlapped,
            NativeMethods.CompactVirtualDiskFlags flags) {

            NativeMethods.CompactVirtualDiskParameters compactParams = new NativeMethods.CompactVirtualDiskParameters();
            compactParams.Version = NativeMethods.CompactVirtualDiskVersion.Version1;

            uint returnCode = NativeMethods.CompactVirtualDisk(
                m_virtualHardDiskHandle,
                flags,
            ref compactParams,
                overlapped);

            if ((overlapped == IntPtr.Zero && NativeMethods.ERROR_SUCCESS != returnCode) ||
                (overlapped != IntPtr.Zero && NativeMethods.ERROR_IO_PENDING != returnCode)) {
                throw new Win32Exception((int)returnCode);
            }

            return returnCode;
        }


        #endregion Public Methods

        #region Public Properties

        /// <summary>
        /// The SafeFileHandle object for the opened VHD.
        /// </summary>
        public SafeFileHandle
        VirtualHardDiskHandle {
            get {
                return m_virtualHardDiskHandle;
            }
        }

        /// <summary>
        /// Indicates the index of the disk when attached.
        /// If the virtual hard disk is not currently attached, -1 will be returned.
        /// </summary>
        public int
        DiskIndex {
            get {
                string path = PhysicalPath;

                if (null != path) {

                    Match match = Regex.Match(path, @"\d+$"); // look for the last digits in the path
                    return System.Convert.ToInt32(match.Value, CultureInfo.InvariantCulture);
                } else {

                    return -1;
                }
            }
        }

        /// <summary>
        /// Indicates whether the current Virtual Hard Disk is attached to the system.
        /// </summary>
        public bool
        IsAttached {
            get {
                return (this.DiskIndex != -1);
            }
        }

        /// <summary>
        /// Retrieves the path to the physical device object that contains a virtual hard disk (VHD), if the VHD is attached.
        /// If it is not attached, NULL will be returned.
        /// </summary>
        public string
        PhysicalPath {
            get {
                uint pathSize = 1024;  // Isn't MAX_PATH 255?
                StringBuilder path = new StringBuilder((int)pathSize);
                uint returnCode = 0;

                returnCode = NativeMethods.GetVirtualDiskPhysicalPath(
                        m_virtualHardDiskHandle,
                    ref pathSize,
                        path);

                if (NativeMethods.ERROR_ERROR_DEV_NOT_EXIST == returnCode) {

                    return null;
                } else if (NativeMethods.ERROR_SUCCESS == returnCode) {

                    return path.ToString();
                } else {

                    throw new Win32Exception((int)returnCode);
                }
            }
        }

        #endregion Public Properties
    }

    #endregion VHD Interop
}
"@
Add-Type -TypeDefinition $code -ReferencedAssemblies 'System.Xml', 'System.Linq', 'System.Xml.Linq'