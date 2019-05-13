/**
 * generated by Xtext 2.15.0
 */
package fr.cea.nabla.nablagen.provider;


import fr.cea.nabla.nablagen.NablagenPackage;
import fr.cea.nabla.nablagen.ReplaceInternalReductionsComponent;

import java.util.Collection;
import java.util.List;

import org.eclipse.emf.common.notify.AdapterFactory;
import org.eclipse.emf.common.notify.Notification;

import org.eclipse.emf.edit.provider.ComposeableAdapterFactory;
import org.eclipse.emf.edit.provider.IItemPropertyDescriptor;
import org.eclipse.emf.edit.provider.ItemPropertyDescriptor;
import org.eclipse.emf.edit.provider.ViewerNotification;

/**
 * This is the item provider adapter for a {@link fr.cea.nabla.nablagen.ReplaceInternalReductionsComponent} object.
 * <!-- begin-user-doc -->
 * <!-- end-user-doc -->
 * @generated
 */
public class ReplaceInternalReductionsComponentItemProvider extends IrWriterComponentItemProvider {
	/**
	 * This constructs an instance from a factory and a notifier.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public ReplaceInternalReductionsComponentItemProvider(AdapterFactory adapterFactory) {
		super(adapterFactory);
	}

	/**
	 * This returns the property descriptors for the adapted class.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public List<IItemPropertyDescriptor> getPropertyDescriptors(Object object) {
		if (itemPropertyDescriptors == null) {
			super.getPropertyDescriptors(object);

			addParentPropertyDescriptor(object);
			addDisabledPropertyDescriptor(object);
			addDumpIrPropertyDescriptor(object);
		}
		return itemPropertyDescriptors;
	}

	/**
	 * This adds a property descriptor for the Parent feature.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected void addParentPropertyDescriptor(Object object) {
		itemPropertyDescriptors.add
			(createItemPropertyDescriptor
				(((ComposeableAdapterFactory)adapterFactory).getRootAdapterFactory(),
				 getResourceLocator(),
				 getString("_UI_ReplaceInternalReductionsComponent_parent_feature"),
				 getString("_UI_PropertyDescriptor_description", "_UI_ReplaceInternalReductionsComponent_parent_feature", "_UI_ReplaceInternalReductionsComponent_type"),
				 NablagenPackage.Literals.REPLACE_INTERNAL_REDUCTIONS_COMPONENT__PARENT,
				 true,
				 false,
				 true,
				 null,
				 null,
				 null));
	}

	/**
	 * This adds a property descriptor for the Disabled feature.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected void addDisabledPropertyDescriptor(Object object) {
		itemPropertyDescriptors.add
			(createItemPropertyDescriptor
				(((ComposeableAdapterFactory)adapterFactory).getRootAdapterFactory(),
				 getResourceLocator(),
				 getString("_UI_ReplaceInternalReductionsComponent_disabled_feature"),
				 getString("_UI_PropertyDescriptor_description", "_UI_ReplaceInternalReductionsComponent_disabled_feature", "_UI_ReplaceInternalReductionsComponent_type"),
				 NablagenPackage.Literals.REPLACE_INTERNAL_REDUCTIONS_COMPONENT__DISABLED,
				 true,
				 false,
				 false,
				 ItemPropertyDescriptor.BOOLEAN_VALUE_IMAGE,
				 null,
				 null));
	}

	/**
	 * This adds a property descriptor for the Dump Ir feature.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected void addDumpIrPropertyDescriptor(Object object) {
		itemPropertyDescriptors.add
			(createItemPropertyDescriptor
				(((ComposeableAdapterFactory)adapterFactory).getRootAdapterFactory(),
				 getResourceLocator(),
				 getString("_UI_ReplaceInternalReductionsComponent_dumpIr_feature"),
				 getString("_UI_PropertyDescriptor_description", "_UI_ReplaceInternalReductionsComponent_dumpIr_feature", "_UI_ReplaceInternalReductionsComponent_type"),
				 NablagenPackage.Literals.REPLACE_INTERNAL_REDUCTIONS_COMPONENT__DUMP_IR,
				 true,
				 false,
				 false,
				 ItemPropertyDescriptor.BOOLEAN_VALUE_IMAGE,
				 null,
				 null));
	}

	/**
	 * This returns ReplaceInternalReductionsComponent.gif.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Object getImage(Object object) {
		return overlayImage(object, getResourceLocator().getImage("full/obj16/ReplaceInternalReductionsComponent"));
	}

	/**
	 * This returns the label text for the adapted class.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public String getText(Object object) {
		String label = ((ReplaceInternalReductionsComponent)object).getName();
		return label == null || label.length() == 0 ?
			getString("_UI_ReplaceInternalReductionsComponent_type") :
			getString("_UI_ReplaceInternalReductionsComponent_type") + " " + label;
	}


	/**
	 * This handles model notifications by calling {@link #updateChildren} to update any cached
	 * children and by creating a viewer notification, which it passes to {@link #fireNotifyChanged}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public void notifyChanged(Notification notification) {
		updateChildren(notification);

		switch (notification.getFeatureID(ReplaceInternalReductionsComponent.class)) {
			case NablagenPackage.REPLACE_INTERNAL_REDUCTIONS_COMPONENT__DISABLED:
			case NablagenPackage.REPLACE_INTERNAL_REDUCTIONS_COMPONENT__DUMP_IR:
				fireNotifyChanged(new ViewerNotification(notification, notification.getNotifier(), false, true));
				return;
		}
		super.notifyChanged(notification);
	}

	/**
	 * This adds {@link org.eclipse.emf.edit.command.CommandParameter}s describing the children
	 * that can be created under this object.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	protected void collectNewChildDescriptors(Collection<Object> newChildDescriptors, Object object) {
		super.collectNewChildDescriptors(newChildDescriptors, object);
	}

}
