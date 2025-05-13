#include <linux/module.h>
#include <linux/init.h>
#include <linux/errno.h>
#include <linux/version.h>
#include <linux/kernel.h>
#include <linux/platform_device.h>
#include <linux/miscdevice.h>
#include <linux/slab.h>
#include <linux/io.h>
#include <linux/of.h>
#include <linux/of_address.h>
#include <linux/fs.h>
#include <linux/uaccess.h>
#include "frame_generator_0.h"

#define DRIVER_NAME "frame_generator_0"
#define MAX_PAYLOAD_SIZE 100
//#define NUM_GENERATORS 4
/* Device registers */
#define dst_0(x) ((x)+0)
#define dst_1(x) ((x)+1)
#define dst_2(x) ((x)+2)
#define dst_3(x) ((x)+3)
#define dst_4(x) ((x)+4)
#define dst_5(x) ((x)+5)
#define src_0(x) ((x)+6)
#define src_1(x) ((x)+7)
#define src_2(x) ((x)+8)
#define src_3(x) ((x)+9)
#define src_4(x) ((x)+10)
#define src_5(x) ((x)+11)
#define length_0(x) ((x)+12)
#define length_1(x) ((x)+13)
#define type_0(x) ((x)+14)
#define type_1(x) ((x)+15)
#define inter_frame_wait(x) ((x)+16)
#define payload(x) ((x)+17)
#define checksum_0(x) ((x)+17)
#define checksum_1(x) ((x)+18)
#define checksum_2(x) ((x)+19)
#define checksum_3(x) ((x)+20)

struct frame_generator_dev {
    struct resource res;
    void __iomem *virtbase;
    packet_data_info_t data;
    packet_payload_t payload;
    frame_generator_read_t readdata;
} dev;

//static frame_generator_dev devs[NUM_GENERATORS];

static void writePacketInfo(packet_data_info_t *writedata) {
    iowrite8(writedata->dst_0, dst_0(dev.virtbase));
    iowrite8(writedata->dst_1, dst_1(dev.virtbase));
    iowrite8(writedata->dst_2, dst_2(dev.virtbase));
    iowrite8(writedata->dst_3, dst_3(dev.virtbase));
    iowrite8(writedata->dst_4, dst_4(dev.virtbase));
    iowrite8(writedata->dst_5, dst_5(dev.virtbase));

    iowrite8(writedata->src_0, src_0(dev.virtbase));
    iowrite8(writedata->src_1, src_1(dev.virtbase));
    iowrite8(writedata->src_2, src_2(dev.virtbase));
    iowrite8(writedata->src_3, src_3(dev.virtbase));
    iowrite8(writedata->src_4, src_4(dev.virtbase));
    iowrite8(writedata->src_5, src_5(dev.virtbase));

    iowrite8(writedata->length_0, length_0(dev.virtbase));
    iowrite8(writedata->length_1, length_1(dev.virtbase));

    iowrite8(writedata->type_0, type_0(dev.virtbase));
    iowrite8(writedata->type_1, type_1(dev.virtbase));

    iowrite8(writedata->frame_wait, inter_frame_wait(dev.virtbase));

    dev.data = *writedata;
}

static void writePayload(packet_payload_t *payload) {
    void __iomem *addr;
    uint16_t length = ((uint16_t)dev.data.length_1 << 8) | dev.data.length_0;
    for(int i = 0; i < length; i++) {
        addr = payload(dev.virtbase) + i;
        iowrite8(payload->data[i], addr);
    }
    dev.payload = *payload;
}

static long frame_generator_ioctl(struct file *f, unsigned int cmd, unsigned long arg) {
    frame_generator_arg_t vla;
    pr_info("ioctl %d\n", cmd);

    switch(cmd){
        case FRAME_WRITE_PACKET_0:
            if(copy_from_user(&vla, (frame_generator_arg_t *)arg, sizeof(frame_generator_arg_t)))
                return -EACCES;
            writePacketInfo(&vla.writedata);
            writePayload(&vla.payload);
            break;
        case FRAME_READ_CHECKSUM_0:
            vla.readdata.checksum_0 = ioread8(checksum_0(dev.virtbase));
            vla.readdata.checksum_1 = ioread8(checksum_1(dev.virtbase));
            vla.readdata.checksum_2 = ioread8(checksum_2(dev.virtbase));
            vla.readdata.checksum_3 = ioread8(checksum_3(dev.virtbase));
            if(copy_to_user(&vla, (frame_generator_arg_t *)arg, sizeof(frame_generator_arg_t)))
                return -EACCES;
            break;
        default:
            return -EINVAL;
    }
    return 0;
}

static const struct file_operations frame_generator_fops = {
	.owner		= THIS_MODULE,
	.unlocked_ioctl = frame_generator_ioctl,
};

static struct miscdevice frame_generator_misc_device = {
	.minor		= MISC_DYNAMIC_MINOR,
	.name		= DRIVER_NAME,
	.fops		= &frame_generator_fops,
};

static int __init frame_generator_probe(struct platform_device *pdev)
{
    packet_data_info_t writedata = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    packet_payload_t payload = {0};
	int ret;

	/* Register ourselves as a misc device: creates /dev/frame_generator_0 */
	ret = misc_register(&frame_generator_misc_device);

	/* Get the address of our registers from the device tree */
	ret = of_address_to_resource(pdev->dev.of_node, 0, &dev.res);
	if (ret) {
		ret = -ENOENT;
		goto out_deregister;
	}

	/* Make sure we can use these registers */
	if (request_mem_region(dev.res.start, resource_size(&dev.res),
			       DRIVER_NAME) == NULL) {
		ret = -EBUSY;
		goto out_deregister;
	}

	/* Arrange access to our registers */
	dev.virtbase = of_iomap(pdev->dev.of_node, 0);
	if (dev.virtbase == NULL) {
		ret = -ENOMEM;
		goto out_release_mem_region;
	}

	/* Set initial values */
	writePacketInfo(&writedata);
    writePayload(&payload);

	return 0;

out_release_mem_region:
	release_mem_region(dev.res.start, resource_size(&dev.res));
out_deregister:
	misc_deregister(&frame_generator_misc_device);
	return ret;
}

/* Clean-up code: release resources */
static int frame_generator_remove(struct platform_device *pdev)
{
	iounmap(dev.virtbase);
	release_mem_region(dev.res.start, resource_size(&dev.res));
	misc_deregister(&frame_generator_misc_device);
	return 0;
}

/* Which "compatible" string(s) to search for in the Device Tree */
#ifdef CONFIG_OF
static const struct of_device_id frame_generator_of_match[] = {
	{ .compatible = "csee4840,frame_generator-1.0" },
	{},
};
MODULE_DEVICE_TABLE(of, frame_generator_of_match);
#endif

/* Information for registering ourselves as a "platform" driver */
static struct platform_driver frame_generator_driver = {
	.driver	= {
		.name	= DRIVER_NAME,
		.owner	= THIS_MODULE,
		.of_match_table = of_match_ptr(frame_generator_of_match),
	},
	.remove	= __exit_p(frame_generator_remove),
};

/* Called when the module is loaded: set things up */
static int __init frame_generator_init(void)
{
	pr_info(DRIVER_NAME ": init\n");
	return platform_driver_probe(&frame_generator_driver, frame_generator_probe);
}

/* Calball when the module is unloaded: release resources */
static void __exit frame_generator_exit(void)
{
	platform_driver_unregister(&frame_generator_driver);
	pr_info(DRIVER_NAME ": exit\n");
}

module_init(frame_generator_init);
module_exit(frame_generator_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("frameGenerator group");
MODULE_DESCRIPTION("frame generator 0 driver");


