/* * Device driver for the ingress packet filter
 *
 * A Platform device implemented using the misc subsystem
 *
 * Stephen A. Edwards
 * Columbia University
 *
 * References:
 * Linux source: Documentation/driver-model/platform.txt
 *               drivers/misc/arm-charlcd.c
 * http://www.linuxforu.com/tag/linux-device-drivers/
 * http://free-electrons.com/docs/
 *
 * "make" to build
 * insmod packet_filter.ko
 *
 * Check code style with
 * checkpatch.pl --file --no-tree packet_filter.c
 */

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
#include "packet_filter.h"

#define DRIVER_NAME "packet_filter"

/* Device registers */
#define INGRESS_PORT_FILTER(x) ((x)+0)

/*
 * Information about our device
 */
struct packet_filter_dev {
	struct resource res; /* Resource: our registers */
	void __iomem *virtbase; /* Where registers can be accessed in memory */
        packet_filter_ingress_port_mask_t ingress_port_mask;
} dev;

static void write_ingress_port_mask(packet_filter_ingress_port_mask_t *mask) {
  iowrite8(mask->mask, INGRESS_PORT_FILTER(dev.virtbase));
  dev.ingress_port_mask = *mask;
}

/*
 * Handle ioctl() calls from userspace:
 * Read or write the segments on single digits.
 * Note extensive error checking of arguments
 */
static long packet_filter_ioctl(struct file *f, unsigned int cmd, unsigned long arg)
{
	packet_filter_arg_t vla;

  pr_info("ioctl %d\n", cmd);

	switch (cmd) {
	case PACKET_FILTER_WRITE_INGRESS_PORT_MASK:
		if (copy_from_user(&vla, (packet_filter_arg_t *) arg,
				   sizeof(packet_filter_arg_t)))
			return -EACCES;
		write_ingress_port_mask(&vla.ingress_port_mask);
		break;

	case PACKET_FILTER_READ_INGRESS_PORT_MASK:
	  vla.ingress_port_mask = dev.ingress_port_mask;
		if (copy_to_user((packet_filter_arg_t *) arg, &vla,
				 sizeof(packet_filter_arg_t)))
			return -EACCES;
		break;

	default:
		return -EINVAL;
	}

	return 0;
}

/* The operations our device knows how to do */
static const struct file_operations packet_filter_fops = {
	.owner		= THIS_MODULE,
	.unlocked_ioctl = packet_filter_ioctl,
};

/* Information about our device for the "misc" framework -- like a char dev */
static struct miscdevice packet_filter_misc_device = {
	.minor		= MISC_DYNAMIC_MINOR,
	.name		= DRIVER_NAME,
	.fops		= &packet_filter_fops,
};

/*
 * Initialization code: get resources (registers) and display
 * a welcome message
 */
static int __init packet_filter_probe(struct platform_device *pdev)
{
  packet_filter_ingress_port_mask_t ingress_mask = { 0b0000 };
	int ret;

	/* Register ourselves as a misc device: creates /dev/packet_filter */
	ret = misc_register(&packet_filter_misc_device);

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
	write_ingress_port_mask(&ingress_mask);

	return 0;

out_release_mem_region:
	release_mem_region(dev.res.start, resource_size(&dev.res));
out_deregister:
	misc_deregister(&packet_filter_misc_device);
	return ret;
}

/* Clean-up code: release resources */
static int packet_filter_remove(struct platform_device *pdev)
{
	iounmap(dev.virtbase);
	release_mem_region(dev.res.start, resource_size(&dev.res));
	misc_deregister(&packet_filter_misc_device);
	return 0;
}

/* Which "compatible" string(s) to search for in the Device Tree */
#ifdef CONFIG_OF
static const struct of_device_id packet_filter_of_match[] = {
	{ .compatible = "csee4840,packet_filter-1.0" },
	{},
};
MODULE_DEVICE_TABLE(of, packet_filter_of_match);
#endif

/* Information for registering ourselves as a "platform" driver */
static struct platform_driver packet_filter_driver = {
	.driver	= {
		.name	= DRIVER_NAME,
		.owner	= THIS_MODULE,
		.of_match_table = of_match_ptr(packet_filter_of_match),
	},
	.remove	= __exit_p(packet_filter_remove),
};

/* Called when the module is loaded: set things up */
static int __init packet_filter_init(void)
{
	pr_info(DRIVER_NAME ": init\n");
	return platform_driver_probe(&packet_filter_driver, packet_filter_probe);
}

/* Calball when the module is unloaded: release resources */
static void __exit packet_filter_exit(void)
{
	platform_driver_unregister(&packet_filter_driver);
	pr_info(DRIVER_NAME ": exit\n");
}

module_init(packet_filter_init);
module_exit(packet_filter_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("PacketFilter group");
MODULE_DESCRIPTION("Packet filter driver");
