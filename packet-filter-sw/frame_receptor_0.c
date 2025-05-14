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
#include "frame_receptor_0.h"

#define DRIVER_NAME "frame_receptor_0"
//#define NUM_RECEPTORS 4
/* Device registers */
#define dst_0(x) ((x)+0)
#define dst_1(x) ((x)+1)
#define dst_2(x) ((x)+2)
#define dst_3(x) ((x)+3)
#define dst_4(x) ((x)+4)
#define dst_5(x) ((x)+5)
#define inter_frame_wait(x) ((x)+6)
#define dstCheck(x) ((x)+7)
#define checksum_0(x) ((x)+8)
#define checksum_1(x) ((x)+9)
#define checksum_2(x) ((x)+10)
#define checksum_3(x) ((x)+11)

struct frame_receptor_dev {
    struct resource res;
    void __iomem *virtbase;
    receptor_data_info_t writedata;
    receptor_data_t readdata;
} dev;

//static frame_receptor_dev devs[NUM_GENERATORS];

static void writeReceptorInfo(receptor_data_info_t *writedata) {
    iowrite8(writedata->dst_0, dst_0(dev.virtbase));
    iowrite8(writedata->dst_1, dst_1(dev.virtbase));
    iowrite8(writedata->dst_2, dst_2(dev.virtbase));
    iowrite8(writedata->dst_3, dst_3(dev.virtbase));
    iowrite8(writedata->dst_4, dst_4(dev.virtbase));
    iowrite8(writedata->dst_5, dst_5(dev.virtbase));

    iowrite8(writedata->frame_wait, inter_frame_wait(dev.virtbase));

    dev.writedata = *writedata;
}


static long frame_receptor_ioctl(struct file *f, unsigned int cmd, unsigned long arg) {
    frame_receptor_arg_t vla;
    pr_info("ioctl %d\n", cmd);

    switch(cmd){
        case RECEPTOR_WRITE_0:
            if(copy_from_user(&vla, (frame_receptor_write_t *)arg, sizeof(frame_receptor_write_t)))
                return -EACCES;
            writeReceptorInfo(&vla.writedata);
            break;
        case RECEPTOR_READ_0:
		    vla.readdata.dstCheck = ioread8(dstCheck_0(dev.virtbase));   
            vla.readdata.checksum_0 = ioread8(checksum_0(dev.virtbase));
            vla.readdata.checksum_1 = ioread8(checksum_1(dev.virtbase));
            vla.readdata.checksum_2 = ioread8(checksum_2(dev.virtbase));
            vla.readdata.checksum_3 = ioread8(checksum_3(dev.virtbase));
            if(copy_to_user((frame_receptor_read_t *)arg, &vla, sizeof(frame_receptor_read_t)))
                return -EACCES;
            break;

        default:
            return -EINVAL;
    }

    return 0;
}

static const struct file_operations frame_receptor_fops = {
	.owner		= THIS_MODULE,
	.unlocked_ioctl = frame_receptor_ioctl,
};

static struct miscdevice frame_receptor_misc_device = {
	.minor		= MISC_DYNAMIC_MINOR,
	.name		= DRIVER_NAME,
	.fops		= &frame_receptor_fops,
};

static int __init frame_receptor_probe(struct platform_device *pdev)
{
    receptor_data_info_t writedata = {0, 0, 0, 0, 0, 0, 0};
	int ret;

	/* Register ourselves as a misc device: creates /dev/frame_receptor */
	ret = misc_register(&frame_receptor_misc_device);

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
	writeReceptorInfo(&writedata);

	return 0;

out_release_mem_region:
	release_mem_region(dev.res.start, resource_size(&dev.res));
out_deregister:
	misc_deregister(&frame_receptor_misc_device);
	return ret;
}

/* Clean-up code: release resources */
static int frame_receptor_remove(struct platform_device *pdev)
{
	iounmap(dev.virtbase);
	release_mem_region(dev.res.start, resource_size(&dev.res));
	misc_deregister(&frame_receptor_misc_device);
	return 0;
}

/* Which "compatible" string(s) to search for in the Device Tree */
#ifdef CONFIG_OF
static const struct of_device_id frame_receptor_of_match[] = {
	{ .compatible = "csee4840,frame_receptor-1.0" },
	{},
};
MODULE_DEVICE_TABLE(of, frame_receptor_of_match);
#endif

/* Information for registering ourselves as a "platform" driver */
static struct platform_driver frame_receptor_driver = {
	.driver	= {
		.name	= DRIVER_NAME,
		.owner	= THIS_MODULE,
		.of_match_table = of_match_ptr(frame_receptor_of_match),
	},
	.remove	= __exit_p(frame_receptor_remove),
};

/* Called when the module is loaded: set things up */
static int __init frame_receptor_init(void)
{
	pr_info(DRIVER_NAME ": init\n");
	return platform_driver_probe(&frame_receptor_driver, frame_receptor_probe);
}

/* Calball when the module is unloaded: release resources */
static void __exit frame_receptor_exit(void)
{
	platform_driver_unregister(&frame_receptor_driver);
	pr_info(DRIVER_NAME ": exit\n");
}

module_init(frame_receptor_init);
module_exit(frame_receptor_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("framereceptor group");
MODULE_DESCRIPTION("frame receptor 0 driver");


